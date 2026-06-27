# Plot a Heat Index raster

Generates a standardized map of the Heat Index for a municipality or
custom area, using the NOAA classification palette.

## Usage

``` r
hi_plot(x, title = "Heat Index", hour = "15h", palette = "continuous", ...)
```

## Arguments

- x:

  A `SpatRaster` returned by
  [`hi_municipality`](https://antcneto.github.io/heatindexbr/reference/hi_municipality.md)
  (with `return_raster = TRUE`) or
  [`hi_shape`](https://antcneto.github.io/heatindexbr/reference/hi_shape.md).

- title:

  Character. Map title. Defaults to `"Heat Index"`.

- hour:

  Character. Hour label for subtitle (e.g. `"15h"`).

- palette:

  Character. Color palette. One of `"continuous"` (default,
  yellow-orange-red) or `"noaa"` (NOAA classes).

- ...:

  Additional arguments passed to `ggplot2` layers.

## Value

A `ggplot` object.

## Examples

``` r
if (FALSE) { # \dontrun{
res <- hi_municipality("Cabrobo", state="PE", return_raster=TRUE)
hi_plot(res$raster, title="Cabrobo - PE")
} # }
```
