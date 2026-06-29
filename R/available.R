#' List available Heat Index products
#'
#' Returns a data frame describing the datasets available for download via
#' [hi_download()] and [hi_municipality()].
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{product}{Product identifier: `"climatology"` or `"synoptic_2025"`.}
#'   \item{period}{Temporal coverage of the product.}
#'   \item{months}{Months available (1–12 for climatology, NA for synoptic).}
#'   \item{hours_local}{Local hours available (0–23 for climatology, 4 synoptic hours for synoptic_2025).}
#'   \item{resolution}{Spatial resolution.}
#'   \item{n_files}{Number of raster files in the dataset.}
#'   \item{format}{Available download formats.}
#'   \item{status}{Whether the product is available for download.}
#' }
#' @export
#' @examples
#' hi_available()
hi_available <- function() {
  data.frame(
    product = c("climatology", "synoptic_2025"),
    period = c("2000-2025", "2025"),
    months = c("1-12", NA),
    hours_local = c("0-23", "0, 9, 15, 21"),
    resolution = c("~1 km", "~1 km"),
    n_files = c(288L, 4L),
    format = c("raster / table", "raster"),
    status = c("available", "available"),
    stringsAsFactors = FALSE
  )
}
