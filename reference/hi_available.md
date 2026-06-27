# List available Heat Index products

Shows which years, resolutions, and hours are currently available.

## Usage

``` r
hi_available()
```

## Value

A `data.frame` with columns `year`, `resolution`, `hours`, and `status`.

## Examples

``` r
hi_available()
#> ℹ Repository: <https://doi.org/10.5281/zenodo.20942619>
#> ℹ Use `hi_download()` to access available products.
#>   year resolution                             hours         status
#> 1 2025     annual                00h, 09h, 15h, 21h      available
#> 2 2025    monthly      00h, 09h, 15h, 21h (Jan-Dec) in preparation
#> 3 2025      daily 00h, 09h, 15h, 21h (all 365 days) in preparation
#> 4 2025     hourly                         all hours in preparation
```
