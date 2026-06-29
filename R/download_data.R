#' Download Heat Index raster data
#'
#' Downloads Heat Index rasters from Zenodo and caches them locally.
#' The default product is the 2000-2025 climatology, which covers all 12 months
#' and 24 local hours at ~1 km resolution for the Brazilian Semiarid region.
#'
#' @param product Character. One of `"climatology"` (default) or
#'   `"synoptic_2025"`. The climatology product provides monthly mean Heat
#'   Index for 2000-2025 at 24 hourly intervals. The synoptic_2025 product
#'   provides annual means for 2025 at four synoptic hours (0h, 9h, 15h, 21h
#'   local time).
#' @param month Integer (1-12). Month of interest. If `NULL`, all months are
#'   returned.
#' @param hour_local Integer (0-23) or character such as `"15h"`. Local hour
#'   (UTC-3). Converted internally to UTC before selecting the band. If `NULL`,
#'   all hours for the requested month are returned.
#' @param cache_dir Character. Directory to store downloaded files. Defaults
#'   to the package cache via [tools::R_user_dir()].
#' @param overwrite Logical. If `TRUE`, re-downloads even if the file is
#'   already cached. Default is `FALSE`.
#' @param quiet Logical. If `TRUE`, suppresses download progress messages.
#'   Default is `FALSE`.
#'
#' @return A [terra::SpatRaster] object. Returns a single-band raster when
#'   both `month` and `hour_local` are specified, a 24-band raster when only
#'   `month` is specified, a 12-band raster when only `hour_local` is
#'   specified, or the full 288-band stack when both are `NULL`.
#'
#' @details
#' **How download works:** the full 288-band stack (~1 GB) is downloaded once
#' and cached locally. Subsequent calls to `hi_download()` read directly from
#' the cache without re-downloading. The requested bands are then extracted
#' in memory. Use `overwrite = TRUE` to force a fresh download of the stack.
#'
#' **UTC conversion:** hours are stored internally as UTC. The `hour_local`
#' argument accepts local time (UTC-3) and converts automatically. For
#' example, `hour_local = 15` retrieves the band at 18h UTC.
#'
#' **Band index:** bands are ordered month-outer, hour-inner:
#' band 1 = January 00h UTC, band 2 = January 01h UTC, ...,
#' band 24 = January 23h UTC, band 25 = February 00h UTC, and so on.
#'
#' @export
#' @examples
#' \dontrun{
#' # January at 15h local time (single band)
#' r <- hi_download(month = 1, hour_local = 15)
#'
#' # All hours for July (24-band raster)
#' r_july <- hi_download(month = 7)
#'
#' # Full 288-band climatology stack
#' r_stack <- hi_download()
#'
#' # Legacy 2025 synoptic product
#' r_2025 <- hi_download(product = "synoptic_2025", hour_local = 15)
#' }
hi_download <- function(product    = c("climatology", "synoptic_2025"),
                        month      = NULL,
                        hour_local = NULL,
                        cache_dir  = NULL,
                        overwrite  = FALSE,
                        quiet      = FALSE) {

  product <- match.arg(product)

  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("heatindexbr", which = "cache")
  }
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

  # ---- synoptic_2025: legacy path ----
  if (product == "synoptic_2025") {
    return(.download_synoptic_2025(hour_local, cache_dir, overwrite, quiet))
  }

  # ---- climatology: always download full stack, then subset ----
  r_stack <- .get_clim_stack(cache_dir, overwrite, quiet)

  # No filter: return full 288-band stack
  if (is.null(month) && is.null(hour_local)) {
    return(r_stack)
  }

  # Build band indices (order: month-outer, hour-inner)
  months_sel <- if (!is.null(month)) as.integer(month) else 1:12
  hours_utc  <- if (!is.null(hour_local)) .local_to_utc(hour_local) else 0:23

  band_idx <- as.vector(outer(hours_utc, (months_sel - 1L) * 24L, "+") + 1L)
  band_idx <- sort(band_idx)

  r <- r_stack[[band_idx]]

  # Name bands
  combos <- expand.grid(hour_utc = hours_utc, month = months_sel)
  combos <- combos[order(combos$month, combos$hour_utc), ]
  names(r) <- sprintf("IC_m%02d_h%02d", combos$month, combos$hour_utc)

  # Warn if any requested band has atende_R2 = FALSE
  .warn_low_r2(months_sel, hours_utc)

  r
}

# ---- internal helpers ----

.clim_base_url <- function() {
  "https://zenodo.org/records/21049066/files"
}

.synoptic_base_url <- function() {
  "https://zenodo.org/records/20942619/files"
}

.local_to_utc <- function(hour_local) {
  if (is.character(hour_local)) {
    hour_local <- as.integer(gsub("[^0-9]", "", hour_local))
  }
  (as.integer(hour_local) + 3L) %% 24L
}

.get_clim_stack <- function(cache_dir, overwrite, quiet) {
  dest <- file.path(cache_dir, "climatology", "IC_288h_stack.tif")
  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)

  if (!file.exists(dest) || overwrite) {
    url <- paste0(.clim_base_url(), "/IC_288h_stack.tif?download=1")
    if (!quiet) {
      cli::cli_inform(c(
        "i" = "Downloading 288-band climatology stack (~1 GB).",
        "i" = "This happens once. Subsequent calls use the local cache."
      ))
    }
    curl::curl_download(url, dest, quiet = quiet)
  }
  terra::rast(dest)
}

.warn_low_r2 <- function(months, hours_utc) {
  # Low-R2 combinations: hours 06-09 UTC in months March-June (atende_R2=FALSE)
  # Based on metodos_vencedores_288h_sem_rf.rds (58 combinations)
  low_hours  <- 6:9
  low_months <- 3:6
  flagged <- any(hours_utc %in% low_hours) && any(months %in% low_months)
  if (flagged) {
    cli::cli_warn(c(
      "!" = "Some requested bands have R\u00b2 < 0.70 in the LOOCV validation.",
      "i" = "This affects hours 06h-09h UTC (03h-06h local) in months March-June.",
      "i" = "Results in these combinations should be interpreted with caution."
    ))
  }
}

.download_synoptic_2025 <- function(hour_local, cache_dir, overwrite, quiet) {
  fname <- "IC_2025_annual_all.tif"
  dest  <- file.path(cache_dir, "synoptic_2025", fname)
  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)

  if (!file.exists(dest) || overwrite) {
    url <- paste0(.synoptic_base_url(), "/", fname, "?download=1")
    if (!quiet) cli::cli_inform("Downloading {fname}...")
    curl::curl_download(url, dest, quiet = quiet)
  }

  r <- terra::rast(dest)

  if (!is.null(hour_local)) {
    if (is.character(hour_local)) {
      hour_local <- as.integer(gsub("[^0-9]", "", hour_local))
    }
    local_hours <- c(0L, 9L, 15L, 21L)
    idx <- which(local_hours == as.integer(hour_local))
    if (length(idx) == 0L) {
      cli::cli_abort(
        "Hour {hour_local}h not available in synoptic_2025. \\
        Available: {paste0(local_hours, 'h', collapse = ', ')}."
      )
    }
    r <- r[[idx]]
  }
  r
}
