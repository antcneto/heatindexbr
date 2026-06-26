#' Extract Heat Index for a municipality
#'
#' Extracts Heat Index statistics for one or more municipalities of the
#' Brazilian Semiarid region, identified by name or IBGE code.
#'
#' @param municipality Character or integer. Municipality name (partial match
#'   allowed, case-insensitive) or 7-digit IBGE code. A vector of names or
#'   codes is accepted.
#' @param state Character. Two-letter state abbreviation (e.g. \code{"PE"},
#'   \code{"BA"}). Recommended when \code{municipality} is a name to avoid
#'   ambiguity across states. Default is \code{NULL} (searches all states).
#' @param hour Character. Synoptic hour. One of \code{"00h"}, \code{"09h"},
#'   \code{"15h"} (default), \code{"21h"}.
#' @param year Integer. Reference year. Default is \code{2025}.
#' @param stat Character vector. Statistics to compute. Any combination of
#'   \code{"mean"} (default), \code{"min"}, \code{"max"}, \code{"median"},
#'   \code{"sd"}, \code{"q25"}, \code{"q75"}.
#' @param return_raster Logical. If \code{TRUE}, also returns the clipped
#'   \code{SpatRaster} object alongside the statistics. Default \code{FALSE}.
#' @param cache_dir Character. Cache directory passed to \code{\link{hi_download}}.
#'
#' @return A \code{data.frame} (or \code{sf} if geometry is available) with
#'   one row per municipality and columns for the requested statistics, plus
#'   \code{noaa_class} (NOAA heat index classification) and \code{code_muni}.
#'   If \code{return_raster = TRUE}, returns a named list with elements
#'   \code{stats} (data frame) and \code{raster} (SpatRaster).
#'
#' @examples
#' \dontrun{
#' # Single municipality by name
#' hi_municipality("Cabrobo", state = "PE")
#'
#' # Multiple municipalities by IBGE code
#' hi_municipality(c(2604155, 2927408), hour = "15h")
#'
#' # Return clipped raster as well
#' result <- hi_municipality("Mossoro", state = "RN", return_raster = TRUE)
#' terra::plot(result$raster)
#' }
#'
#' @importFrom stats setNames
#' @export
hi_municipality <- function(municipality,
                             state        = NULL,
                             hour         = "15h",
                             year         = 2025,
                             stat         = "mean",
                             return_raster = FALSE,
                             cache_dir    = NULL) {

  hour <- match.arg(hour, c("00h","09h","15h","21h"))
  stat <- match.arg(stat,
                    c("mean","min","max","median","sd","q25","q75"),
                    several.ok = TRUE)

  # Carrega lista de municípios do Semiárido (embutida no pacote)
  mun_semi <- heatindexbr::semiarido_municipios

  # Filtra por estado se fornecido
  if (!is.null(state)) {
    state    <- toupper(state)
    mun_semi <- mun_semi[mun_semi$abbrev_state %in% state, ]
    if (nrow(mun_semi) == 0)
      cli::cli_abort("State {.val {state}} has no municipalities in the Semiarid.")
  }

  # Identifica municípios: por código ou por nome
  if (is.numeric(municipality) || grepl("^\\d+$", municipality[1])) {
    codigos <- as.character(municipality)
    selecionados <- mun_semi[mun_semi$code_muni %in% codigos, ]
  } else {
    # Busca parcial case-insensitive
    padrao <- paste(municipality, collapse="|")
    idx    <- grepl(padrao, mun_semi$name_muni, ignore.case = TRUE)
    selecionados <- mun_semi[idx, ]
  }

  if (nrow(selecionados) == 0)
    cli::cli_abort(
      c("No municipality found matching {.val {municipality}}.",
        "i" = "Use {.fn hi_search} to find valid names.")
    )

  if (nrow(selecionados) > 1 && length(municipality) == 1 &&
      !is.numeric(municipality)) {
    cli::cli_inform(
      c("!" = "{nrow(selecionados)} municipalities matched {.val {municipality}}:",
        paste0("  ", selecionados$name_muni, " (", selecionados$abbrev_state, ")",
               collapse = "\n"),
        "i" = "Use {.arg state} to narrow results.")
    )
  }

  # Baixa o raster se necessário
  paths  <- hi_download(year=year, hours=hour, cache_dir=cache_dir, quiet=TRUE)
  r      <- terra::rast(paths[hour])

  # Reprojecta geometria dos municípios para o CRS do raster
  mun_sf <- sf::st_transform(selecionados$geometry_sf, terra::crs(r))

  # Extração com exactextractr se disponível, senão terra::extract
  if (requireNamespace("exactextractr", quietly=TRUE)) {
    vals <- exactextractr::exact_extract(r, mun_sf, stat)
    if (is.vector(vals)) vals <- setNames(as.data.frame(t(vals)), stat)
  } else {
    vals_raw <- terra::extract(r, terra::vect(mun_sf), fun=mean, na.rm=TRUE)
    vals     <- data.frame(mean = vals_raw[,2])
  }

  # Monta resultado
  resultado <- cbind(
    selecionados[, c("code_muni","name_muni","abbrev_state")],
    vals
  )
  resultado$noaa_class <- .noaa_classify(resultado$mean)
  resultado$hour       <- hour
  resultado$year       <- year

  if (return_raster) {
    r_clip <- terra::mask(terra::crop(r, terra::vect(mun_sf)), terra::vect(mun_sf))
    return(list(stats = resultado, raster = r_clip))
  }

  resultado
}

# Classificação NOAA (interna)
.noaa_classify <- function(ic) {
  cut(ic,
      breaks = c(-Inf, 27, 32, 41, 54, Inf),
      labels = c("No caution","Caution","Extreme caution","Danger","Extreme danger"),
      right  = FALSE)
}
