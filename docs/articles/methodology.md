# Methodology: why trust the raster?

This article documents the interpolation methodology behind the
`IC_2025_annual_all.tif` raster distributed by `heatindexbr`. The goal
is to give users enough information to assess the raster’s fitness for
their specific use case.

------------------------------------------------------------------------

## The Heat Index

The Heat Index (IC) is computed using the Rothfusz (1990) regression
equation, which combines air temperature (T, °C) and relative humidity
(RH, %) into a single thermal comfort index. Wind speed is not
considered, which makes the index tractable for regional-scale mapping
where homogeneous wind data are unavailable. The four synoptic hours
used — 00h, 09h, 15h, and 21h (local UTC-3) — correspond to standard
INMET observation times.

------------------------------------------------------------------------

## Input data

**Weather stations:** INMET automatic stations, 2025 (annual means). A
completeness threshold of ≥75% was applied, resulting in 59–73 stations
per hour depending on data availability. The 15h hour (18h UTC) achieves
the largest network: 73 stations.

**Covariates used in the best models:**

| Covariate             | Source                      | Resolution |
|-----------------------|-----------------------------|------------|
| Altitude              | SRTM (BRA_elv_msk.tif)      | ~90 m      |
| NDVI                  | MODIS MOD13A3, 2025         | ~1 km      |
| ERA5-Land T2m         | Google Earth Engine export  | ~9 km      |
| Distance to coastline | Computed via ne_coastline() | —          |

------------------------------------------------------------------------

## Method comparison

Fifteen spatial interpolation methods were compared across all four
synoptic hours using leave-one-out cross-validation (LOOCV). The
candidate methods included kriging with external drift (KDE) with
various covariate combinations, ordinary kriging, linear regression
(with coordinates and altitude), Random Forest, RF + Kriging of
residuals, IDW, and thin-plate splines.

**Winning method by hour:**

| Hour (local) | Method | Covariates                         | R²        | RMSE       |
|--------------|--------|------------------------------------|-----------|------------|
| 00h          | KDE    | alt + dist_coast + NDVI + ERA5_00h | 0.863     | —          |
| 09h          | KDE    | alt + NDVI                         | 0.885     | —          |
| 15h          | KDE    | alt + ERA5_18h                     | **0.884** | **1.03°C** |
| 21h          | KDE    | alt + dist_coast + NDVI + ERA5_00h | 0.819     | —          |

The covariates selected vary by hour, reflecting distinct physical
processes:

- **NDVI** contributes at night (00h, 21h): local land-surface processes
  in the Caatinga biome modulate nocturnal temperature more than
  synoptic forcing.
- **ERA5** dominates at 15h: regional synoptic forcing drives daytime
  temperature gradients more strongly than local vegetation effects.
- **Distance to coastline** is relevant at night, when sea-breeze
  effects and radiative cooling create a clear coastal gradient.

------------------------------------------------------------------------

## Why Random Forest was rejected

Random Forest achieved high R² under standard LOOCV. However, block
spatial cross-validation (spatial folds) revealed substantial spatial
leakage:

| Hour | LOOCV R² | Block CV R² | ΔR²      |
|------|----------|-------------|----------|
| 21h  | ~0.86    | ~0.68       | **0.18** |
| 15h  | ~0.88    | ~0.80       | **0.08** |

KDE’s R² remained stable across both protocols. We interpret this as KDE
genuinely capturing the spatial structure of the Heat Index, while RF
was partially memorising the local neighbourhood of each station.

------------------------------------------------------------------------

## Why indirect interpolation (T + RH → IC) was rejected

An alternative workflow would interpolate temperature and humidity
separately, then compute IC from the interpolated fields. This approach
was tested and rejected: it introduced a systematic bias of **+0.246°C
at 15h** relative to direct IC interpolation. The direct approach is
used throughout.

------------------------------------------------------------------------

## Residual diagnostics

For the 15h hour, residuals of the KDE model were subjected to two
tests:

**Variogram analysis:** All fitted models (spherical, exponential,
Gaussian) converged to a pure nugget effect: Sill = 0, Nugget ≈ 1.05.
This means no residual spatial autocorrelation remains after fitting —
the model has absorbed all systematic spatial structure.

**Moran’s I:** I = −0.027, p = 0.864. Residuals are spatially random.

Together, these results confirm that the KDE model is well-specified and
that the residual variance reflects only local measurement noise, not
unmodelled spatial patterns.

------------------------------------------------------------------------

## Independence of covariates

Partial correlations computed on a sample of 100,000 prediction-grid
pixels confirm that altitude and ERA5 capture independent physical
processes:

- IC × ERA5 \| altitude = **0.977** (p \< 0.001)
- IC × altitude \| ERA5 = **−0.929** (p \< 0.001)

Simple correlations for comparison:

- IC × ERA5 = 0.933
- IC × altitude = −0.778
- altitude × ERA5 = −0.529

The raster is not redundant with an elevation model — ERA5 explains
nearly all remaining variance after altitude is controlled for,
confirming the thermodynamic basis of the interpolation.

------------------------------------------------------------------------

## Error decay with distance

A concern with sparse station networks is that prediction errors
increase monotonically with distance from the nearest station. The
correlation between LOOCV absolute error and distance to the nearest
neighbour station is **−0.109 (non-significant)**. Prediction error does
not grow with distance.

The largest errors occur in the 33–55 km range, corresponding to coastal
and Agreste zones with steep gradients. Interior Semiarid areas show
smaller errors because of genuine climatic homogeneity — not because
stations are closer.

Consequently, the distance-to-station raster (`dist_estacao_km.tif`)
should be interpreted as a **descriptive map of the monitoring
network**, not as a predictive confidence interval.

------------------------------------------------------------------------

## LOOCV summary (15h / 18h UTC, 73 stations)

| Statistic                          | Value    |
|------------------------------------|----------|
| Mean absolute error                | 0.775°C  |
| Median absolute error              | 0.651°C  |
| Maximum absolute error             | 2.808°C  |
| Folds with NA                      | 0        |
| Nearest-neighbour distance: min    | 33 km    |
| Nearest-neighbour distance: median | 86.8 km  |
| Nearest-neighbour distance: max    | 248.4 km |

------------------------------------------------------------------------

## Raster technical specifications

| Property    | Value                                       |
|-------------|---------------------------------------------|
| File        | `IC_2025_annual_all.tif`                    |
| Bands       | 4 (IC_00h, IC_09h, IC_15h, IC_21h)          |
| CRS         | EPSG:5880 (SIRGAS 2000 / Brazil Polyconic)  |
| Resolution  | ~1 km                                       |
| Extent      | Brazilian Semiarid (CONDEL/SUDENE 176/2024) |
| Compression | DEFLATE                                     |
| File size   | 17.1 MB                                     |
| NA values   | Ocean / outside Semiarid boundary           |

> **Do not use the WGS84 version** (`IC_2025_annual_all_WGS84.tif`). A
> reprojection artefact clips the eastern boundary of the domain. The
> EPSG:5880 version is the correct product.

------------------------------------------------------------------------

## Population exposure

Annual mean Heat Index at 15h was cross-referenced with 2022 IBGE Census
population data (31,035,363 inhabitants across 1,477 municipalities):

| NOAA class                | Municipalities | Population   | Share |
|---------------------------|----------------|--------------|-------|
| No caution (\< 27°C)      | 93             | 979,000      | 3.2%  |
| Caution (27–32°C)         | 813            | 16.8 million | 54.1% |
| Extreme caution (32–41°C) | 640            | 13.3 million | 42.7% |
| Danger / Extreme danger   | 0              | —            | —     |

Annual means represent a **conservative lower bound** on exposure. Daily
peak values in specific months can exceed IC \> 41°C. Analysis of
extremes is reserved for a forthcoming publication.

------------------------------------------------------------------------

## Reference

Rothfusz, L. P. (1990). *The heat index equation (or, more than you ever
wanted to know about heat index)*. NWS Technical Attachment SR 90-23.
National Weather Service, Fort Worth, TX.
