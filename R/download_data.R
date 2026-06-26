#' Download Heat Index rasters for the Brazilian Semiarid
#'
#' Downloads pre-computed Heat Index rasters from the package repository
#' (Zenodo) to a local cache directory. Only downloads files not already
#' present in the cache.
#'
#' @param year Integer. Reference year. Currently only 2025 is available.
#'   Additional years will be added as data are processed.
#' @param hours Character vector. Synoptic hours to download. One or more of
#'   \code{"00h"}, \code{"09h"}, \code{"15h"}, \code{"21h"}.
#'   Default is \code{"15h"} (peak heat stress hour).
#' @param cache_dir Character. Path to local cache directory.
#'   Defaults to a persistent user cache via \code{tools::R_user_dir()}.
#' @param overwrite Logical. If \code{TRUE}, re-downloads files even if
#'   already cached. Default is \code{FALSE}.
#' @param quiet Logical. If \code{FALSE} (default), prints download progress.
#'
#' @return Invisibly returns a named character vector of local file paths,
#'   one per requested hour.
#'
#' @examples
#' \dontrun{
#' # Download only the 15h raster (default)
#' paths <- hi_download(year = 2025)
#'
#' # Download all four synoptic hours
#' paths <- hi_download(year = 2025, hours = c("00h","09h","15h","21h"))
#' }
#'
#' @importFrom stats setNames
#' @export
hi_download <- function(year    = 2025,
                        hours   = "15h",
                        cache_dir = NULL,
                        overwrite = FALSE,
                        quiet     = FALSE) {

  # Valida argumentos
  horas_validas <- c("00h","09h","15h","21h")
  hours <- match.arg(hours, horas_validas, several.ok = TRUE)

  if (!year %in% c(2025L)) {
    cli::cli_abort(
      c("Year {.val {year}} is not available yet.",
        "i" = "Currently available: {.val 2025}.")
    )
  }

  # Diretório de cache
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("heatindexbr", which = "cache")
  }
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

  # Mapa hora → nome do arquivo no Zenodo
  # (URLs serão atualizadas após publicação no Zenodo)
  hora_para_arquivo <- c(
    "00h" = "IC_21h_local.tif",   # 00h UTC = 21h local
    "09h" = "IC_09h_local.tif",   # 12h UTC = 09h local
    "15h" = "IC_15h_local.tif",   # 18h UTC = 15h local
    "21h" = "IC_00h_local.tif"    # 00h UTC = 21h → 03h UTC = 00h local
  )

  # URL base do Zenodo (substituir pelo DOI real após publicação)
  zenodo_base <- paste0(
    "https://zenodo.org/records/XXXXXXX/files/"
  )

  paths <- setNames(character(length(hours)), hours)

  for (h in hours) {
    nome_arquivo <- paste0(year, "_", hora_para_arquivo[h])
    destino      <- file.path(cache_dir, nome_arquivo)
    paths[h]     <- destino

    if (file.exists(destino) && !overwrite) {
      if (!quiet)
        cli::cli_inform("Using cached file for {h}: {.file {destino}}")
      next
    }

    url <- paste0(zenodo_base, nome_arquivo)
    if (!quiet)
      cli::cli_inform("Downloading {h} raster ({year})...")

    tryCatch(
      curl::curl_download(url, destino, quiet = quiet),
      error = function(e) {
        cli::cli_abort(
          c("Failed to download {h} raster.",
            "x" = conditionMessage(e),
            "i" = "Check your internet connection or try {.fn hi_download} later.")
        )
      }
    )

    if (!quiet)
      cli::cli_inform(c("v" = "Downloaded: {.file {destino}}"))
  }

  invisible(paths)
}
