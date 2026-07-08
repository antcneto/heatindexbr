#' Compute population exposure to Heat Index by NOAA class
#'
#' Downloads the municipal Heat Index table with population data from Zenodo
#' and returns population counts by NOAA thermal class for the requested
#' month, local hour, and census year. Results can be aggregated at the
#' municipality, state, or Semiarid level.
#'
#' @param month Integer (1-12). Month of interest. Required.
#' @param hour_local Integer (0-23). Local hour (UTC-3). Required.
#' @param census_year Integer. Census year for population weights. One of
#'   2000, 2010, or 2022. Defaults to 2022. The package applies the
#'   following convention: use 2000 for analyses covering 2000-2009,
#'   2010 for 2010-2021, and 2022 for 2022 onward.
#' @param by Character. Aggregation level. One of "municipality" (default),
#'   "state", or "semiarid" (total for the entire region).
#' @param cache_dir Character. Cache directory for downloaded files.
#'   Defaults to the package cache via tools::R_user_dir().
#'
#' @return A data frame with columns depending on the aggregation level:
#' \describe{
#'   \item{code_muni}{IBGE municipality code (only when by = "municipality").}
#'   \item{name_muni}{Municipality name (only when by = "municipality").}
#'   \item{abbrev_state}{State abbreviation (when by = "municipality" or "state").}
#'   \item{month}{Requested month.}
#'   \item{hour_local}{Requested local hour.}
#'   \item{hour_utc}{Corresponding UTC hour.}
#'   \item{ic_mean}{Mean Heat Index for the municipality (degrees C).}
#'   \item{noaa_class}{NOAA thermal class: No caution, Caution, Extreme caution, Danger, or Extreme danger.}
#'   \item{population}{Total population in the NOAA class for the census year.}
#'   \item{population_share}{Share of total population in the NOAA class (0 to 1).}
#' }
#'
#' @details
#' The NOAA Heat Index classification thresholds used are:
#' No caution (IC below 27 degrees C), Caution (27 to 32 degrees C),
#' Extreme caution (32 to 41 degrees C), Danger (41 to 54 degrees C),
#' and Extreme danger (above 54 degrees C).
#'
#' Population data come from the IBGE Census. The pop_2000 column covers
#' the 2000 census, pop_2010 covers the 2010 census, and pop_2022 covers
#' the 2022 census. Use the census year closest to your analysis period.
#'
#' The function downloads the ~35 MB population table from Zenodo on first
#' use and caches it locally. Subsequent calls read from the cache.
#'
#' @importFrom stats aggregate
#' @export
#' @examples
#' \dontrun{
#' # Population exposure in January at 15h local time, 2022 census
#' hi_exposure(month = 1, hour_local = 15)
#'
#' # Aggregated by state
#' hi_exposure(month = 7, hour_local = 12, by = "state")
#'
#' # Total Semiarid exposure
#' hi_exposure(month = 1, hour_local = 15, by = "semiarid")
#'
#' # Using 2000 census weights
#' hi_exposure(month = 1, hour_local = 15, census_year = 2000)
#' }
hi_exposure <- function(month,
                        hour_local,
                        census_year = 2022,
                        by          = c("municipality", "state", "semiarid"),
                        cache_dir   = NULL) {

  by <- match.arg(by)

  if (missing(month) || is.null(month))
    cli::cli_abort("Please provide {.arg month} (1-12).")
  if (missing(hour_local) || is.null(hour_local))
    cli::cli_abort("Please provide {.arg hour_local} (0-23).")

  month      <- as.integer(month)
  hour_local <- .parse_hour(hour_local)
  hour_utc   <- .local_to_utc(hour_local)

  if (!census_year %in% c(2000L, 2010L, 2022L))
    cli::cli_abort(
      "{.arg census_year} must be 2000, 2010, or 2022. Got {census_year}."
    )

  pop_col <- paste0("pop_", census_year)

  # Download population table
  tbl <- .load_pop_table(cache_dir)

  # Filter to requested month and hour
  result <- tbl[tbl$month == month & tbl$hour_utc == hour_utc, ]

  if (nrow(result) == 0L)
    cli::cli_abort(
      "No data found for month {month} and hour_local {hour_local}h (UTC {hour_utc}h)."
    )

  result$hour_local <- hour_local
  result$population <- result[[pop_col]]
  result$noaa_class <- as.character(.noaa_classify(result$ic_mean))

  # Warn for low-R2 combinations
  .warn_low_r2(month, hour_utc)

  # Aggregate
  if (by == "municipality") {
    out <- result[, c("code_muni", "name_muni", "abbrev_state",
                      "month", "hour_local", "hour_utc",
                      "ic_mean", "noaa_class", "population")]
    total_pop <- sum(out$population, na.rm = TRUE)
    out$population_share <- out$population / total_pop
    return(out[order(out$abbrev_state, out$name_muni), ])
  }

  if (by == "state") {
    agg <- aggregate(
      cbind(population = result$population),
      by = list(
        abbrev_state = result$abbrev_state,
        noaa_class   = result$noaa_class
      ),
      FUN = sum, na.rm = TRUE
    )
    agg$month      <- month
    agg$hour_local <- hour_local
    agg$hour_utc   <- hour_utc
    total_pop <- sum(agg$population, na.rm = TRUE)
    agg$population_share <- agg$population / total_pop
    return(agg[order(agg$abbrev_state, agg$noaa_class), ])
  }

  if (by == "semiarid") {
    agg <- aggregate(
      cbind(population = result$population),
      by = list(noaa_class = result$noaa_class),
      FUN = sum, na.rm = TRUE
    )
    agg$month      <- month
    agg$hour_local <- hour_local
    agg$hour_utc   <- hour_utc
    total_pop <- sum(agg$population, na.rm = TRUE)
    agg$population_share <- agg$population / total_pop
    return(agg[order(agg$noaa_class), ])
  }
}

# ---- internal helper ----

.load_pop_table <- function(cache_dir) {
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("heatindexbr", which = "cache")
  }
  dest <- file.path(cache_dir, "climatology", "ic_municipal_288h_pop.csv")
  if (!file.exists(dest)) {
    url <- paste0(
      "https://zenodo.org/records/21049066/files/",
      "ic_municipal_288h_pop.csv?download=1"
    )
    dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
    cli::cli_inform("Downloading municipal Heat Index table with population (~35 MB)...")
    curl::curl_download(url, dest)
  }
  utils::read.csv(dest, stringsAsFactors = FALSE)
}
