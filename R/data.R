#' Brazilian Semiarid municipalities
#'
#' A dataset containing the 1,477 municipalities of the Brazilian Semiarid
#' region as defined by Res. CONDEL/SUDENE 176/2024.
#'
#' @format An \code{sf} object with 1,477 rows and 4 variables:
#' \describe{
#'   \item{code_muni}{7-digit IBGE municipality code (character)}
#'   \item{name_muni}{Municipality name}
#'   \item{abbrev_state}{Two-letter state abbreviation}
#'   \item{geometry}{Municipality polygon (EPSG:4326)}
#' }
#'
#' @source IBGE (2024), Malha Municipal; SUDENE (2024), Res. CONDEL 176/2024
#' @examples
#' head(semiarido_municipios)
"semiarido_municipios"
