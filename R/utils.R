#' @keywords internal
.get_semiarido_sf <- function() {
  df <- heatindexbr::semiarido_municipios
  geom <- sf::st_as_sfc(df$geometry_wkt, crs = "EPSG:4326")
  sf::st_sf(
    code_muni    = df$code_muni,
    name_muni    = df$name_muni,
    abbrev_state = df$abbrev_state,
    geometry     = geom
  )
}

