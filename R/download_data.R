#' Download Heat Index rasters for the Brazilian Semiarid
#'
#' Downloads pre-computed Heat Index rasters from Zenodo
#' (DOI: 10.5281/zenodo.20942619) to a local cache directory.
#'
#' @param year Integer. Reference year. Currently only \code{2025}.
#' @param hour Character or NULL. Local synoptic hour: \code{"00h"},
#'   \code{"09h"}, \code{"15h"} (default), \code{"21h"}, or \code{NULL}
#'   to load all four hours as a multi-band SpatRaster.
#' @param resolution Character. Temporal resolution. Currently only
#'   \code{"annual"} is available.
#' @param month Integer (1-12). Required when \code{resolution = "monthly"}.
#' @param day Integer (1-365). Required when \code{resolution = "daily"}.
#' @param cache_dir Character. Local cache directory.
#' @param overwrite Logical. Re-download even if cached? Default \code{FALSE}.
#' @param quiet Logical. Suppress messages? Default \code{FALSE}.
#'
#' @return A loaded \code{SpatRaster} object.
#'
#' @references
#' Dataset: \doi{10.5281/zenodo.20942619}
#'
#' @examples
#' \donttest{
#' r <- hi_download(year = 2025, hour = "15h")
#' }
#'
#' @importFrom stats setNames
#' @export
hi_download <- function(year       = 2025,
                        hour       = "15h",
                        resolution = "annual",
                        month      = NULL,
                        day        = NULL,
                        cache_dir  = NULL,
                        overwrite  = FALSE,
                        quiet      = FALSE) {

  # Valida hora
  if (!is.null(hour))
    hour <- match.arg(hour, c("00h","09h","15h","21h"))

  # Valida resolucao
  resolution <- match.arg(resolution,
                           c("annual","monthly","daily","hourly"))

  # Disponibilidade
  disponivel <- list(
    annual  = c(2025L),
    monthly = integer(0),
    daily   = integer(0),
    hourly  = integer(0)
  )

  if (!as.integer(year) %in% disponivel[[resolution]]) {
    anos <- disponivel[[resolution]]
    if (length(anos) == 0)
      cli::cli_abort(
        c("{.val {resolution}} resolution is not yet available.",
          "i" = "Currently available: {.val annual} for year {.val 2025}."))
    cli::cli_abort(
      c("Year {.val {year}} not available for {.val {resolution}} resolution.",
        "i" = "Available: {.val {anos}}."))
  }

  # Cache
  if (is.null(cache_dir))
    cache_dir <- tools::R_user_dir("heatindexbr", which = "cache")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

  # Nome do arquivo — sempre o stack completo
  nm_arquivo <- paste0("IC_", year, "_", resolution, "_all.tif")
  destino    <- file.path(cache_dir, nm_arquivo)

  # URL Zenodo
  url <- paste0("https://zenodo.org/records/20942619/files/",
                nm_arquivo, "?download=1")

  if (!file.exists(destino) || overwrite) {
    if (!quiet)
      cli::cli_inform(
        c("i" = "Downloading {.val {nm_arquivo}} from Zenodo (~17 MB)...",
          "i" = "DOI: {.url https://doi.org/10.5281/zenodo.20942619}"))
    tryCatch(
      curl::curl_download(url, destino, quiet = quiet),
      error = function(e)
        cli::cli_abort(
          c("Failed to download raster.",
            "x" = conditionMessage(e),
            "i" = "Visit {.url https://zenodo.org/records/20942619}"))
    )
    if (!quiet) cli::cli_inform(c("v" = "Saved to {.file {destino}}"))
  } else {
    if (!quiet) cli::cli_inform(c("v" = "Using cached: {.file {destino}}"))
  }

  # Carrega o raster
  r <- terra::rast(destino)

  # Filtra banda se hora especifica foi pedida
  if (!is.null(hour)) {
    banda <- paste0("IC_", hour)
    if (!banda %in% names(r))
      cli::cli_abort(
        c("Band {.val {banda}} not found.",
          "i" = "Available: {.val {names(r)}}."))
    r <- r[[banda]]
  }

  r
}

