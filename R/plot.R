#' Plot a Heat Index raster
#'
#' Generates a standardized map of the Heat Index for a municipality or
#' custom area, using the NOAA classification palette.
#'
#' @param x A \code{SpatRaster} returned by \code{\link{hi_municipality}}
#'   (with \code{return_raster = TRUE}) or \code{\link{hi_shape}}.
#' @param title Character. Map title. Defaults to \code{"Heat Index"}.
#' @param hour Character. Hour label for subtitle (e.g. \code{"15h"}).
#' @param palette Character. Color palette. One of \code{"continuous"}
#'   (default, yellow-orange-red) or \code{"noaa"} (NOAA classes).
#' @param ... Additional arguments passed to \code{ggplot2} layers.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' \dontrun{
#' res <- hi_municipality("Cabrobo", state="PE", return_raster=TRUE)
#' hi_plot(res$raster, title="Cabrobo - PE")
#' }
#'
#' @export
hi_plot <- function(x,
                    title   = "Heat Index",
                    hour    = "15h",
                    palette = "continuous",
                    ...) {

  if (!inherits(x, "SpatRaster"))
    cli::cli_abort("{.arg x} must be a {.cls SpatRaster}.")

  if (!requireNamespace("tidyterra", quietly=TRUE))
    cli::cli_abort('Package {.pkg tidyterra} required. Install with install.packages("tidyterra").')

  r_wgs <- terra::project(x, "EPSG:4326")

  p <- ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = r_wgs, na.rm = TRUE)

  if (palette == "continuous") {
    p <- p + ggplot2::scale_fill_gradientn(
      colours  = c("#ffffcc","#fed976","#fd8d3c","#e31a1c","#800026"),
      name     = "IC (\u00b0C)",
      na.value = "transparent"
    )
  } else {
    p <- p + ggplot2::scale_fill_stepsn(
      colours = c("#ffffcc","#fed976","#fd8d3c","#e31a1c","#800026"),
      breaks  = c(27, 32, 41, 54),
      name    = "NOAA class",
      labels  = c("No caution","Caution","Extreme caution","Danger"),
      na.value = "transparent"
    )
  }

  p +
    ggplot2::labs(
      title    = title,
      subtitle = paste0("Heat Index at ", hour, " local time | Rothfusz (1990)"),
      caption  = paste0(
        "Source: INMET 2025 | ERA5-Land (ECMWF)\n",
        "heatindexbr package | Campos Neto et al. (2026)"
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid   = ggplot2::element_blank(),
      plot.title   = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(size = 7, colour = "grey40")
    )
}
