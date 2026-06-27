#' Search for municipalities in the Brazilian Semiarid
#'
#' Helper to find valid municipality names and IBGE codes before calling
#' \code{\link{hi_municipality}}. Municipality names follow the IBGE
#' uppercase standard without diacritics (e.g. \code{"MOSSORO"} not
#' \code{"Mossoró"}).
#'
#' @param name Character. Partial name to search (case-insensitive,
#'   accent-insensitive). Use uppercase without accents for best results.
#' @param state Character. Optional two-letter state filter.
#'
#' @return A \code{data.frame} with \code{code_muni}, \code{name_muni},
#'   and \code{abbrev_state}.
#'
#' @examples
#' hi_search("MOSSORO")
#' hi_search("CABROBO", state = "PE")
#'
#' @export
hi_search <- function(name, state = NULL) {
  mun <- heatindexbr::semiarido_municipios
  if (!is.null(state))
    mun <- mun[toupper(mun$abbrev_state) %in% toupper(state), ]
  idx <- grepl(toupper(name), mun$name_muni, ignore.case = FALSE)
  mun[idx, c("code_muni","name_muni","abbrev_state")]
}

