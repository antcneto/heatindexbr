#' Plot a Heat Index raster
#'
#' Generates a standardized map of the Heat Index for a municipality or
#' custom area, using a continuous or NOAA classification palette.
#'
#' @param x A \code{SpatRaster} returned by \code{\link{hi_download}},
#'   \code{\link{hi_municipality}} (with \code{return_raster = TRUE}),
#'   or \code{\link{hi_shape}}.
#' @param title Character. Map title. Defaults to \code{"Heat Index"}.
#' @param subtitle Character or \code{NULL}. Map subtitle. If \code{NULL}
#'   (default), no subtitle is shown. Pass any string to display a custom
#'   subtitle below the title.
#' @param palette Character. Color palette. One of \code{"continuous"}
#'   (default, yellow-orange-red) or \code{"noaa"} (NOAA classes).
#' @param ... Additional arguments passed to \code{ggplot2} layers.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' \dontrun{
#' r <- hi_download(month = 1, hour_local = 15)
#' hi_plot(r, title = "Heat Index, January 15h")
#' hi_plot(r, title = "Ceara", subtitle = "Heat Index at 15h local time, January climatology 2000-2025")
#' }
#'
#' @export
hi_plot <- function(x,
                    title    = "Heat Index",
                    subtitle = NULL,
                    palette  = "continuous",
                    ...) {

  if (!inherits(x, "SpatRaster"))
    cli::cli_abort("{.arg x} must be a {.cls SpatRaster}.")

  if (!requireNamespace("tidyterra", quietly = TRUE))
    cli::cli_abort('Package {.pkg tidyterra} required. Install with install.packages("tidyterra").')

  r_wgs <- terra::project(x, "EPSG:4326")

  p <- ggplot2::ggplot() +
    tidyterra::geom_spatraster(data = r_wgs, na.rm = TRUE)

  if (palette == "continuous") {
    p <- p + ggplot2::scale_fill_gradientn(
      colours  = c("#ffffcc", "#fed976", "#fd8d3c", "#e31a1c", "#800026"),
      name     = "IC (\u00b0C)",
      na.value = "transparent"
    )
  } else {
    p <- p + ggplot2::scale_fill_stepsn(
      colours  = c("#ffffcc", "#fed976", "#fd8d3c", "#e31a1c", "#800026"),
      breaks   = c(27, 32, 41, 54),
      name     = "NOAA class",
      labels   = c("No caution", "Caution", "Extreme caution", "Danger"),
      na.value = "transparent"
    )
  }

  p +
    ggplot2::labs(
      title    = title,
      subtitle = subtitle,
      caption  = "Source: INMET 2025, ERA5-Land (ECMWF). heatindexbr package. Campos Neto (2026)"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid   = ggplot2::element_blank(),
      plot.title   = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(size = 7, colour = "grey40")
    )
}
