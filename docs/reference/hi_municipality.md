# Extract Heat Index for municipalities of the Brazilian Semiarid

Extract Heat Index for municipalities of the Brazilian Semiarid

## Usage

``` r
hi_municipality(
  municipality,
  state = NULL,
  hour = "15h",
  year = 2025,
  resolution = "annual",
  month = NULL,
  day = NULL,
  stat = "mean",
  return_raster = FALSE,
  cache_dir = NULL
)
```

## Arguments

- municipality:

  Character or integer. Municipality name (uppercase, no accents) or
  7-digit IBGE code. Use
  [`hi_search`](https://antcneto.github.io/heatindexbr/reference/hi_search.md)
  to find valid names. Names follow IBGE uppercase standard without
  accents (e.g. `"MOSSORO"` not `"Mossoro"` or `"Mossoro"`).

- state:

  Character. Two-letter state abbreviation (e.g. `"RN"`).

- hour:

  Character or NULL. Local hour: `"00h"`, `"09h"`, `"15h"` (default),
  `"21h"`, or `NULL` for all hours.

- year:

  Integer. Year (default `2025`).

- resolution:

  Character. Temporal resolution (default `"annual"`).

- month:

  Integer. Month (1-12) if `resolution = "monthly"`.

- day:

  Integer. Day (1-365) if `resolution = "daily"`.

- stat:

  Character vector. Statistics: `"mean"` (default), `"min"`, `"max"`,
  `"median"`, `"sd"`, `"q25"`, `"q75"`.

- return_raster:

  Logical. Also return clipped SpatRaster?

- cache_dir:

  Character. Cache directory.

## Value

A `data.frame` with statistics and NOAA classification, or a named list
with `stats` and `raster` if `return_raster = TRUE`.

## Examples

``` r
# \donttest{
hi_municipality("MOSSORO", state = "RN", hour = "15h")
#>   code_muni name_muni abbrev_state     mean hour year resolution
#> 1   2408003   MOSSORO           RN 34.22471  15h 2025     annual
#>        noaa_class
#> 1 Extreme caution
# }
```
