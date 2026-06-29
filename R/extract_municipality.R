#' Extract Heat Index statistics for one or more municipalities
#'
#' Returns mean Heat Index and standard deviation for the requested
#' municipality, month, and local hour. By default, data are retrieved from
#' the pre-computed municipal table (fast, no raster download required). Set
#' `source = "raster"` to extract directly from the downloaded stack.
#'
#' @param municipality Character. Municipality name in IBGE uppercase
#'   convention (no accents). Use [hi_search()] to find the correct name.
#' @param state Character. Two-letter state abbreviation (e.g. `"RN"`).
#'   Recommended when the name is not unique across states.
#' @param month Integer (1-12). Month of interest. If `NULL`, all 12 months
#'   are returned.
#' @param hour_local Integer (0-23) or character such as `"15h"`. Local hour
#'   (UTC-3). If `NULL`, all 24 hours are returned.
#' @param product Character. `"climatology"` (default) or `"synoptic_2025"`.
#' @param source Character. `"table"` (default) reads from the pre-computed
#'   municipal CSV (~29 MB, cached on first use). `"raster"` downloads the
#'   full stack and extracts pixel statistics for the municipality polygon.
#' @param return_raster Logical. If `TRUE` and `source = "raster"`, also
#'   returns the masked SpatRaster. Default is `FALSE`.
#' @param cache_dir Character. Cache directory passed to [hi_download()].
#'
#' @return A data frame with columns `code_muni`, `name_muni`,
#'   `abbrev_state`, `month`, `hour_local`, `hour_utc`, `ic_mean`, `ic_sd`,
#'   and `noaa_class`. When `return_raster = TRUE`, a named list with
#'   elements `stats` and `raster`.
#'
#' @importFrom stats sd
#' @export
#' @examples
#' \dontrun{
#' # January at 15h local (fast, table source)
#' hi_municipality("MOSSORO", state = "RN", month = 1, hour_local = 15)
#'
#' # All months and hours
#' hi_municipality("MOSSORO", state = "RN")
#'
#' # Legacy synoptic_2025
#' hi_municipality("MOSSORO", state = "RN",
#'                 product = "synoptic_2025", hour_local = 15)
#' }
hi_municipality <- function(municipality,
                             state         = NULL,
                             month         = NULL,
                             hour_local    = NULL,
                             product       = c("climatology", "synoptic_2025"),
                             source        = c("table", "raster"),
                             return_raster = FALSE,
                             cache_dir     = NULL) {

  product <- match.arg(product)
  source  <- match.arg(source)

  if (product == "synoptic_2025") {
    return(.hi_municipality_synoptic(municipality, state, hour_local,
                                     return_raster, cache_dir))
  }

  mun_sf <- .get_semiarido_sf()
  hit    <- .match_municipality(mun_sf, municipality, state)

  # ---- table source (fast) ----
  if (source == "table") {
    tbl <- .load_clim_table(cache_dir)

    result <- tbl[tbl$code_muni == hit$code_muni, ]

    if (!is.null(month)) {
      result <- result[result$month %in% as.integer(month), ]
    }
    if (!is.null(hour_local)) {
      h_utc  <- .local_to_utc(hour_local)
      result <- result[result$hour_utc %in% h_utc, ]
    }

    result$hour_local <- (result$hour_utc - 3L) %% 24L
    result$noaa_class <- as.character(.noaa_classify(result$ic_mean))

    # Warn for low-R2 combinations
    if (!is.null(month) && !is.null(hour_local)) {
      .warn_low_r2(as.integer(month), .local_to_utc(hour_local))
    }

    return(result[, c("code_muni", "name_muni", "abbrev_state",
                      "month", "hour_local", "hour_utc",
                      "ic_mean", "ic_sd", "noaa_class")])
  }

  # ---- raster source ----
  r_full <- hi_download(product = "climatology", month = month,
                        hour_local = hour_local, cache_dir = cache_dir)

  r_crop <- terra::crop(r_full, terra::vect(hit))
  r_mask <- terra::mask(r_crop, terra::vect(hit))
  vals   <- terra::values(r_mask, na.rm = TRUE)

  if (!is.matrix(vals)) vals <- matrix(vals, ncol = 1)

  months_sel <- if (!is.null(month)) as.integer(month) else 1:12
  hours_utc  <- if (!is.null(hour_local)) .local_to_utc(hour_local) else 0:23
  combos     <- expand.grid(hour_utc = hours_utc, month = months_sel)
  combos     <- combos[order(combos$month, combos$hour_utc), ]

  stats <- data.frame(
    code_muni    = hit$code_muni,
    name_muni    = hit$name_muni,
    abbrev_state = hit$abbrev_state,
    month        = combos$month,
    hour_utc     = combos$hour_utc,
    hour_local   = (combos$hour_utc - 3L) %% 24L,
    ic_mean      = colMeans(vals, na.rm = TRUE),
    ic_sd        = apply(vals, 2, sd, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  stats$noaa_class <- as.character(.noaa_classify(stats$ic_mean))

  if (return_raster) return(list(stats = stats, raster = r_mask))
  stats
}

# ---- internal helpers ----

.match_municipality <- function(mun_sf, municipality, state) {
  idx <- toupper(mun_sf$name_muni) == toupper(municipality)
  if (!is.null(state)) {
    idx <- idx & toupper(mun_sf$abbrev_state) == toupper(state)
  }
  if (sum(idx) == 0L) {
    cli::cli_abort(
      "Municipality {.val {municipality}} not found. \\
      Use {.fn hi_search} to check the correct name."
    )
  }
  if (sum(idx) > 1L) {
    cli::cli_abort(
      "Multiple matches for {.val {municipality}}. \\
      Specify {.arg state} to disambiguate."
    )
  }
  mun_sf[idx, ]
}

.load_clim_table <- function(cache_dir) {
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("heatindexbr", which = "cache")
  }
  dest <- file.path(cache_dir, "climatology", "ic_municipal_288h.csv")
  if (!file.exists(dest)) {
    url <- paste0(
      "https://zenodo.org/records/21049066/files/",
      "ic_municipal_288h.csv?download=1"
    )
    dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
    cli::cli_inform("Downloading municipal Heat Index table (~29 MB)...")
    curl::curl_download(url, dest)
  }
  utils::read.csv(dest, stringsAsFactors = FALSE)
}

.noaa_classify <- function(ic) {
  cut(ic,
      breaks = c(-Inf, 27, 32, 41, 54, Inf),
      labels = c("No caution", "Caution", "Extreme caution",
                 "Danger", "Extreme danger"),
      right  = FALSE)
}

.hi_municipality_synoptic <- function(municipality, state, hour_local,
                                       return_raster, cache_dir) {
  mun_sf <- .get_semiarido_sf()
  hit    <- .match_municipality(mun_sf, municipality, state)

  r_full <- hi_download(product = "synoptic_2025",
                        hour_local = hour_local,
                        cache_dir = cache_dir)
  r_crop <- terra::crop(r_full, terra::vect(hit))
  r_mask <- terra::mask(r_crop, terra::vect(hit))

  if (is.null(hour_local)) {
    local_hours <- c(0L, 9L, 15L, 21L)
  } else {
    if (is.character(hour_local)) {
      hour_local <- as.integer(gsub("[^0-9]", "", hour_local))
    }
    local_hours <- as.integer(hour_local)
  }

  vals <- terra::values(r_mask, na.rm = TRUE)
  if (!is.matrix(vals)) vals <- matrix(vals, ncol = 1)

  stats <- data.frame(
    code_muni    = hit$code_muni,
    name_muni    = hit$name_muni,
    abbrev_state = hit$abbrev_state,
    hour_local   = paste0(local_hours, "h"),
    year         = 2025L,
    ic_mean      = colMeans(vals, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  stats$noaa_class <- as.character(.noaa_classify(stats$ic_mean))

  if (return_raster) return(list(stats = stats, raster = r_mask))
  stats
}
