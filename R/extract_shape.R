#' Extract Heat Index statistics for a custom spatial area
#'
#' Extracts Heat Index statistics from the climatology raster for any
#' user-supplied `sf` polygon. The full 288-band stack is downloaded and
#' cached on first use; subsequent calls read from the local cache.
#'
#' @param shape An `sf` object or a path to a shapefile.
#' @param month Integer (1-12). Month of interest. If `NULL`, all 12 months
#'   are returned.
#' @param hour_local Integer (0-23) or character such as `"15h"`. Local hour
#'   (UTC-3). If `NULL`, all 24 hours are returned.
#' @param product Character. `"climatology"` (default) or `"synoptic_2025"`.
#' @param stat Character. Statistic to compute over pixels. One of `"mean"`
#'   (default), `"median"`, `"min"`, or `"max"`. If `exactextractr` is
#'   installed, it is used for more accurate polygon extraction.
#' @param return_raster Logical. If `TRUE`, also returns the masked
#'   SpatRaster cropped to `shape`. Default is `TRUE`.
#' @param cache_dir Character. Cache directory passed to [hi_download()].
#'
#' @return A named list with:
#' \describe{
#'   \item{stats}{A data frame with extraction results per month and hour.}
#'   \item{raster}{A SpatRaster masked to `shape` (only if
#'     `return_raster = TRUE`).}
#' }
#'
#' @importFrom utils tail
#' @importFrom stats setNames sd
#' @export
#' @examples
#' \donttest{
#' # area <- sf::st_read("my_area.shp")
#' # res  <- hi_shape(area, month = 1, hour_local = 15)
#' # res$stats
#' }
hi_shape <- function(shape,
                     month         = NULL,
                     hour_local    = NULL,
                     product       = c("climatology", "synoptic_2025"),
                     stat          = "mean",
                     return_raster = TRUE,
                     cache_dir     = NULL) {

  product <- match.arg(product)

  # ---- validate shape ----
  if (is.character(shape)) {
    if (!file.exists(shape))
      cli::cli_abort("File not found: {.file {shape}}")
    shape <- sf::st_read(shape, quiet = TRUE)
  }
  if (!inherits(shape, "sf"))
    cli::cli_abort("{.arg shape} must be an {.cls sf} object or a shapefile path.")

  # ---- download raster ----
  r_full <- hi_download(product    = product,
                        month      = month,
                        hour_local = hour_local,
                        cache_dir  = cache_dir,
                        quiet      = TRUE)

  # ---- reproject shape to raster CRS ----
  shape_proj <- sf::st_transform(shape, terra::crs(r_full))
  sv         <- terra::vect(shape_proj)

  # ---- crop and mask ----
  r_crop <- terra::crop(r_full, sv)
  r_mask <- terra::mask(r_crop, sv)
  n_ok   <- terra::global(!is.na(r_mask[[1]]), "sum")[[1]]

  # ---- extract per band ----
  if (requireNamespace("exactextractr", quietly = TRUE)) {
    vals <- exactextractr::exact_extract(r_mask, shape_proj, stat)
    if (is.vector(vals)) vals <- as.data.frame(setNames(as.list(vals), names(r_mask)))
  } else {
    vals_mat <- terra::global(r_mask, stat, na.rm = TRUE)
    vals     <- as.data.frame(t(vals_mat[[1]]))
    names(vals) <- names(r_mask)
  }

  # ---- build stats data frame ----
  months_sel <- if (!is.null(month)) as.integer(month) else 1:12
  hours_utc  <- if (!is.null(hour_local)) .local_to_utc(hour_local) else 0:23

  if (product == "synoptic_2025") {
    hours_local_sel <- if (!is.null(hour_local)) {
      as.integer(gsub("[^0-9]", "", as.character(hour_local)))
    } else c(0L, 9L, 15L, 21L)
    combos <- data.frame(hour_local = hours_local_sel, hour_utc = NA_integer_)
  } else {
    combos <- expand.grid(hour_utc = hours_utc, month = months_sel)
    combos <- combos[order(combos$month, combos$hour_utc), ]
    combos$hour_local <- (combos$hour_utc - 3L) %% 24L
  }

  stats_df <- cbind(
    sf::st_drop_geometry(shape),
    data.frame(
      month      = if (product == "climatology") combos$month else NA_integer_,
      hour_local = combos$hour_local,
      hour_utc   = combos$hour_utc,
      n_pixels   = n_ok,
      stringsAsFactors = FALSE
    ),
    vals
  )
  rownames(stats_df) <- NULL

  out <- list(stats = stats_df)
  if (return_raster) out$raster <- r_mask
  out
}
