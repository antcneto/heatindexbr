#' List available Heat Index products
#'
#' Shows which years, resolutions, and hours are currently available.
#'
#' @return A \code{data.frame} with columns \code{year},
#'   \code{resolution}, \code{hours}, and \code{status}.
#'
#' @examples
#' hi_available()
#'
#' @export
hi_available <- function() {
  df <- data.frame(
    year       = c(2025, 2025, 2025, 2025),
    resolution = c("annual","monthly","daily","hourly"),
    hours      = c("00h, 09h, 15h, 21h",
                   "00h, 09h, 15h, 21h (Jan-Dec)",
                   "00h, 09h, 15h, 21h (all 365 days)",
                   "all hours"),
    status     = c("available","in preparation",
                   "in preparation","in preparation"),
    stringsAsFactors = FALSE
  )
  cli::cli_inform(c(
    "i" = "Repository: {.url https://doi.org/10.5281/zenodo.20942619}",
    "i" = "Use {.fn hi_download} to access available products."
  ))
  df
}

