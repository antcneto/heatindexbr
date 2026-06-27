#' Extract Heat Index for municipalities of the Brazilian Semiarid
#'
#' @param municipality Character or integer. Municipality name (uppercase,
#'   no accents) or 7-digit IBGE code. Use \code{\link{hi_search}} to
#'   find valid names. Names follow IBGE uppercase standard without accents
#'   (e.g. \code{"MOSSORO"} not \code{"Mossoro"} or \code{"Mossoro"}).
#' @param state Character. Two-letter state abbreviation (e.g. \code{"RN"}).
#' @param hour Character or NULL. Local hour: \code{"00h"}, \code{"09h"},
#'   \code{"15h"} (default), \code{"21h"}, or \code{NULL} for all hours.
#' @param year Integer. Year (default \code{2025}).
#' @param resolution Character. Temporal resolution (default \code{"annual"}).
#' @param month Integer. Month (1-12) if \code{resolution = "monthly"}.
#' @param day Integer. Day (1-365) if \code{resolution = "daily"}.
#' @param stat Character vector. Statistics: \code{"mean"} (default),
#'   \code{"min"}, \code{"max"}, \code{"median"}, \code{"sd"},
#'   \code{"q25"}, \code{"q75"}.
#' @param return_raster Logical. Also return clipped SpatRaster?
#' @param cache_dir Character. Cache directory.
#'
#' @return A \code{data.frame} with statistics and NOAA classification,
#'   or a named list with \code{stats} and \code{raster} if
#'   \code{return_raster = TRUE}.
#'
#' @examples
#' \donttest{
#' hi_municipality("MOSSORO", state = "RN", hour = "15h")
#' }
#'
#' @importFrom stats setNames
#' @importFrom utils tail
#' @export
hi_municipality <- function(municipality,
                             state         = NULL,
                             hour          = "15h",
                             year          = 2025,
                             resolution    = "annual",
                             month         = NULL,
                             day           = NULL,
                             stat          = "mean",
                             return_raster = FALSE,
                             cache_dir     = NULL) {

  stat <- match.arg(stat,
                    c("mean","min","max","median","sd","q25","q75"),
                    several.ok = TRUE)

  # Reconstrói sf a partir do WKT (evita problema de sf_column no .rda)
  mun_semi <- .get_semiarido_sf()

  if (!is.null(state))
    mun_semi <- mun_semi[toupper(mun_semi$abbrev_state) %in% toupper(state), ]

  if (is.numeric(municipality) ||
      all(grepl("^\\d+$", as.character(municipality)))) {
    selecionados <- mun_semi[mun_semi$code_muni %in%
                               as.character(municipality), ]
  } else {
    idx <- grepl(paste(toupper(municipality), collapse = "|"),
                 mun_semi$name_muni, ignore.case = FALSE)
    selecionados <- mun_semi[idx, ]
  }

  if (nrow(selecionados) == 0)
    cli::cli_abort(
      c("No municipality found matching {.val {municipality}}.",
        "i" = "Use {.fn hi_search} to find valid names.",
        "i" = "Names use IBGE uppercase standard (e.g. MOSSORO not Mossoro)."))

  horas_loop <- if (is.null(hour)) c("00h","09h","15h","21h") else hour

  resultado <- lapply(horas_loop, function(hora_atual) {
    r <- hi_download(year       = year,
                     hour       = hora_atual,
                     resolution = resolution,
                     month      = month,
                     day        = day,
                     cache_dir  = cache_dir,
                     quiet      = TRUE)

    mun_proj <- sf::st_transform(selecionados, terra::crs(r))

    if (requireNamespace("exactextractr", quietly = TRUE)) {
      vals <- exactextractr::exact_extract(r, mun_proj, stat)
      if (is.vector(vals))
        vals <- as.data.frame(stats::setNames(as.list(vals), stat))
    } else {
      v    <- terra::extract(r, terra::vect(mun_proj), fun = mean, na.rm = TRUE)
      vals <- data.frame(mean = v[, 2])
    }

    df <- cbind(
      sf::st_drop_geometry(
        selecionados[, c("code_muni","name_muni","abbrev_state")]),
      vals,
      data.frame(hour       = hora_atual,
                 year       = year,
                 resolution = resolution,
                 stringsAsFactors = FALSE)
    )
    if ("mean" %in% stat)
      df$noaa_class <- .noaa_classify(df$mean)
    df
  })

  resultado <- do.call(rbind, resultado)
  rownames(resultado) <- NULL

  if (return_raster) {
    r_last <- hi_download(year       = year,
                          hour       = utils::tail(horas_loop, 1),
                          resolution = resolution,
                          month      = month,
                          day        = day,
                          cache_dir  = cache_dir,
                          quiet      = TRUE)
    mun_v  <- terra::vect(sf::st_transform(selecionados, terra::crs(r_last)))
    r_clip <- terra::mask(terra::crop(r_last, mun_v), mun_v)
    return(list(stats = resultado, raster = r_clip))
  }

  resultado
}

#' @keywords internal
.noaa_classify <- function(ic) {
  cut(ic,
      breaks = c(-Inf, 27, 32, 41, 54, Inf),
      labels = c("No caution","Caution","Extreme caution",
                 "Danger","Extreme danger"),
      right  = FALSE)
}

