
#' Search for municipalities in the Brazilian Semiarid
#'
#' Helper to find valid municipality names and IBGE codes before calling
#' \code{\link{hi_municipality}}.
#'
#' @param name Character. Partial name to search (case-insensitive).
#'   Names are stored in uppercase (IBGE standard), so accents are ignored.
#' @param state Character. Optional two-letter state filter.
#'
#' @return A \code{data.frame} with \code{code_muni}, \code{name_muni},
#'   and \code{abbrev_state}.
#'
#' @examples
#' \donttest{
#' hi_search("MOSSORO")
#' hi_search("SAO", state = "CE")
#' }
#'
#' @export
hi_search <- function(name, state = NULL) {
  mun <- heatindexbr::semiarido_municipios
  if (!is.null(state))
    mun <- mun[toupper(mun$abbrev_state) %in% toupper(state), ]
  idx <- grepl(toupper(name), mun$name_muni, ignore.case = FALSE)
  sf::st_drop_geometry(mun[idx, c("code_muni","name_muni","abbrev_state")])
}

