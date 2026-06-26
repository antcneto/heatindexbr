#' Extract Heat Index for a custom area
#'
#' Clips and extracts Heat Index statistics for any area defined by a
#' user-supplied shapefile or \code{sf} object.
#'
#' @param shape An \code{sf} object or a path to a shapefile (.shp).
#' @param hour Character. Synoptic hour. Default \code{"15h"}.
#' @param year Integer. Reference year. Default \code{2025}.
#' @param stat Character vector. Statistics to compute. Default \code{"mean"}.
#' @param return_raster Logical. If \code{TRUE}, also returns the clipped raster.
#' @param cache_dir Character. Cache directory.
#'
#' @return A list with elements \code{stats} (data frame with statistics per
#'   feature) and, if \code{return_raster = TRUE}, \code{raster} (SpatRaster).
#'
#' @examples
#' \dontrun{
#' # Extract for a custom region
#' my_area <- sf::st_read("minha_area.shp")
#' result  <- hi_shape(my_area, hour = "15h")
#' }
#'
#' @export
hi_shape <- function(shape,
                     hour         = "15h",
                     year         = 2025,
                     stat         = "mean",
                     return_raster = FALSE,
                     cache_dir    = NULL) {

  hour <- match.arg(hour, c("00h","09h","15h","21h"))

  # Carrega shape se for caminho
  if (is.character(shape)) {
    if (!file.exists(shape))
      cli::cli_abort("File not found: {.file {shape}}")
    shape <- sf::st_read(shape, quiet = TRUE)
  }

  if (!inherits(shape, "sf"))
    cli::cli_abort("{.arg shape} must be an {.cls sf} object or path to a shapefile.")

  # Baixa raster
  paths <- hi_download(year=year, hours=hour, cache_dir=cache_dir, quiet=TRUE)
  r     <- terra::rast(paths[hour])

  # Reprojecta
  shape_proj <- sf::st_transform(shape, terra::crs(r))
  shape_vect <- terra::vect(shape_proj)

  # Verifica sobreposição com o Semiárido
  r_crop <- tryCatch(
    terra::crop(r, shape_vect),
    error = function(e)
      cli::cli_abort("Shape does not overlap with the Brazilian Semiarid raster.")
  )
  r_clip <- terra::mask(r_crop, shape_vect)

  n_validos <- terra::global(!is.na(r_clip), "sum")[[1]]
  if (n_validos == 0)
    cli::cli_warn("No valid pixels found within the supplied shape.")

  # Estatísticas
  if (requireNamespace("exactextractr", quietly=TRUE)) {
    vals <- exactextractr::exact_extract(r, shape_proj, stat)
    if (is.vector(vals)) vals <- as.data.frame(t(vals))
    names(vals) <- stat
  } else {
    vals <- data.frame(mean = terra::global(r_clip, "mean", na.rm=TRUE)[[1]])
  }

  resultado <- list(
    stats = cbind(sf::st_drop_geometry(shape), vals,
                  hour=hour, year=year, n_pixels=n_validos)
  )
  if (return_raster) resultado$raster <- r_clip

  resultado
}
