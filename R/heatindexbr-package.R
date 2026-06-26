#' heatindexbr: Heat Index Mapping for the Brazilian Semiarid Region
#'
#' @description
#' The \pkg{heatindexbr} package provides pre-computed Heat Index (HI) rasters
#' for the Brazilian Semiarid region (1,477 municipalities) at four synoptic
#' hours (00h, 09h, 15h, 21h local time) and tools for spatial extraction.
#'
#' ## Main functions
#'
#' - \code{\link{hi_download}}: Download rasters from Zenodo repository
#' - \code{\link{hi_municipality}}: Extract HI for municipalities by name or code
#' - \code{\link{hi_shape}}: Extract HI for any area (shapefile or sf object)
#' - \code{\link{hi_search}}: Search for valid municipality names
#' - \code{\link{hi_plot}}: Generate standardized HI maps
#'
#' ## Data
#'
#' Rasters are interpolated using External Drift Kriging with altitude
#' (SRTM) and ERA5-Land temperature as covariates, validated against
#' INMET automatic weather station data (2025) with LOOCV R² = 0.884
#' at 15h local time.
#'
#' ## Citation
#'
#' Campos Neto, A. et al. (2026). Heat Index mapping for the Brazilian
#' Semiarid: spatial interpolation under sparse monitoring networks.
#' International Journal of Climatology. (in review)
#'
#' @keywords internal
"_PACKAGE"
