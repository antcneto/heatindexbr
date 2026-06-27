# Extract Heat Index for a custom spatial area

Extract Heat Index for a custom spatial area

## Usage

``` r
hi_shape(
  shape,
  hour = "15h",
  year = 2025,
  resolution = "annual",
  month = NULL,
  day = NULL,
  stat = "mean",
  return_raster = TRUE,
  cache_dir = NULL
)
```

## Arguments

- shape:

  An `sf` object or path to a shapefile.

- hour:

  Character or NULL. Local hour (default `"15h"`).

- year:

  Integer. Year (default `2025`).

- resolution:

  Character. Temporal resolution (default `"annual"`).

- month:

  Integer. Month if `resolution = "monthly"`.

- day:

  Integer. Day if `resolution = "daily"`.

- stat:

  Character vector. Statistics (default `"mean"`).

- return_raster:

  Logical. Return clipped SpatRaster? Default `TRUE`.

- cache_dir:

  Character. Cache directory.

## Value

A list with `stats` and optionally `raster`.

## Examples

``` r
# \donttest{
# area <- sf::st_read("my_area.shp")
# res  <- hi_shape(area, hour = "15h")
# }
```
