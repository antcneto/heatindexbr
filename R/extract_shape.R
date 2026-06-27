#' Extract Heat Index for a custom spatial area
#'
#' @param shape An \code{sf} object or path to a shapefile.
#' @param hour Character or NULL. Local hour (default \code{"15h"}).
#' @param year Integer. Year (default \code{2025}).
#' @param resolution Character. Temporal resolution (default \code{"annual"}).
#' @param month Integer. Month if \code{resolution = "monthly"}.
#' @param day Integer. Day if \code{resolution = "daily"}.
#' @param stat Character vector. Statistics (default \code{"mean"}).
#' @param return_raster Logical. Return clipped SpatRaster? Default \code{TRUE}.
#' @param cache_dir Character. Cache directory.
#'
#' @return A list with \code{stats} and optionally \code{raster}.
#'
#' @examples
#' \donttest{
#' # area <- sf::st_read("my_area.shp")
#' # res  <- hi_shape(area, hour = "15h")
#' }
#'
#' @importFrom utils tail
#' @importFrom stats setNames
#' @export
hi_shape <- function(shape,
                     hour          = "15h",
                     year          = 2025,
                     resolution    = "annual",
                     month         = NULL,
                     day           = NULL,
                     stat          = "mean",
                     return_raster = TRUE,
                     cache_dir     = NULL) {

  if (is.character(shape)) {
    if (!file.exists(shape))
      cli::cli_abort("File not found: {.file {shape}}")
    shape <- sf::st_read(shape, quiet = TRUE)
  }
  if (!inherits(shape, "sf"))
    cli::cli_abort("{.arg shape} must be an {.cls sf} object or shapefile path.")

  horas_loop <- if (is.null(hour)) c("00h","09h","15h","21h") else hour

  stats_list <- lapply(horas_loop, function(hora_atual) {
    r   <- hi_download(year       = year,
                       hour       = hora_atual,
                       resolution = resolution,
                       month      = month,
                       day        = day,
                       cache_dir  = cache_dir,
                       quiet      = TRUE)
    sp  <- sf::st_transform(shape, terra::crs(r))
    sv  <- terra::vect(sp)
    r_c <- terra::mask(terra::crop(r, sv), sv)
    n_ok <- terra::global(!is.na(r_c), "sum")[[1]]

    if (requireNamespace("exactextractr", quietly = TRUE)) {
      vals <- exactextractr::exact_extract(r, sp, stat)
      if (is.vector(vals))
        vals <- as.data.frame(stats::setNames(as.list(vals), stat))
    } else {
      vals <- data.frame(mean = terra::global(r_c, "mean", na.rm = TRUE)[[1]])
    }

    cbind(sf::st_drop_geometry(shape), vals,
          data.frame(hour       = hora_atual,
                     year       = year,
                     resolution = resolution,
                     n_pixels   = n_ok,
                     stringsAsFactors = FALSE))
  })

  out <- list(stats = do.call(rbind, stats_list))
  rownames(out$stats) <- NULL

  if (return_raster) {
    r_last <- hi_download(year       = year,
                          hour       = utils::tail(horas_loop, 1),
                          resolution = resolution,
                          month      = month,
                          day        = day,
                          cache_dir  = cache_dir,
                          quiet      = TRUE)
    sv <- terra::vect(sf::st_transform(shape, terra::crs(r_last)))
    out$raster <- terra::mask(terra::crop(r_last, sv), sv)
  }

  out
}

