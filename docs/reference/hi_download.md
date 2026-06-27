# Download Heat Index rasters for the Brazilian Semiarid

Downloads pre-computed Heat Index rasters from Zenodo (DOI:
10.5281/zenodo.20942619) to a local cache directory.

## Usage

``` r
hi_download(
  year = 2025,
  hour = "15h",
  resolution = "annual",
  month = NULL,
  day = NULL,
  cache_dir = NULL,
  overwrite = FALSE,
  quiet = FALSE
)
```

## Arguments

- year:

  Integer. Reference year. Currently only `2025`.

- hour:

  Character or NULL. Local synoptic hour: `"00h"`, `"09h"`, `"15h"`
  (default), `"21h"`, or `NULL` to load all four hours as a multi-band
  SpatRaster.

- resolution:

  Character. Temporal resolution. Currently only `"annual"` is
  available.

- month:

  Integer (1-12). Required when `resolution = "monthly"`.

- day:

  Integer (1-365). Required when `resolution = "daily"`.

- cache_dir:

  Character. Local cache directory.

- overwrite:

  Logical. Re-download even if cached? Default `FALSE`.

- quiet:

  Logical. Suppress messages? Default `FALSE`.

## Value

A loaded `SpatRaster` object.

## References

Dataset:
[doi:10.5281/zenodo.20942619](https://doi.org/10.5281/zenodo.20942619)

## Examples

``` r
# \donttest{
r <- hi_download(year = 2025, hour = "15h")
#> ✔ Using cached:
#>   /Users/antcneto/Library/Caches/org.R-project.R/R/heatindexbr/IC_2025_annual_all.tif
# }
```
