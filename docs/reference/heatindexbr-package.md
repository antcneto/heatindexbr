# heatindexbr: Heat Index Mapping for the Brazilian Semiarid Region

The heatindexbr package provides pre-computed Heat Index (HI) rasters
for the Brazilian Semiarid region (1,477 municipalities) at four
synoptic hours (00h, 09h, 15h, 21h local time) and tools for spatial
extraction.

### Main functions

- [`hi_download`](https://antcneto.github.io/heatindexbr/reference/hi_download.md):
  Download rasters from Zenodo repository

- [`hi_municipality`](https://antcneto.github.io/heatindexbr/reference/hi_municipality.md):
  Extract HI for municipalities by name or code

- [`hi_shape`](https://antcneto.github.io/heatindexbr/reference/hi_shape.md):
  Extract HI for any area (shapefile or sf object)

- [`hi_search`](https://antcneto.github.io/heatindexbr/reference/hi_search.md):
  Search for valid municipality names

- [`hi_plot`](https://antcneto.github.io/heatindexbr/reference/hi_plot.md):
  Generate standardized HI maps

### Data

Rasters are interpolated using External Drift Kriging with altitude
(SRTM) and ERA5-Land temperature as covariates, validated against INMET
automatic weather station data (2025) with LOOCV R² = 0.884 at 15h local
time.

### Citation

Campos Neto, A. et al. (2026). Heat Index mapping for the Brazilian
Semiarid: spatial interpolation under sparse monitoring networks.
International Journal of Climatology. (in review)

## See also

Useful links:

- <https://github.com/antcamposneto/heatindexbr>

- [doi:10.5281/zenodo.20942619](https://doi.org/10.5281/zenodo.20942619)

- <https://antcneto.github.io/heatindexbr/>

- Report bugs at <https://github.com/antcamposneto/heatindexbr/issues>

## Author

**Maintainer**: Antônio Campos Neto <antonio.camposneto9@gmail.com>
([ORCID](https://orcid.org/0009-0007-3844-3869))
