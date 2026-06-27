# Search for municipalities in the Brazilian Semiarid

Helper to find valid municipality names and IBGE codes before calling
[`hi_municipality`](https://antcneto.github.io/heatindexbr/reference/hi_municipality.md).
Municipality names follow the IBGE uppercase standard without diacritics
(e.g. `"MOSSORO"` not `"Mossoró"`).

## Usage

``` r
hi_search(name, state = NULL)
```

## Arguments

- name:

  Character. Partial name to search (case-insensitive,
  accent-insensitive). Use uppercase without accents for best results.

- state:

  Character. Optional two-letter state filter.

## Value

A `data.frame` with `code_muni`, `name_muni`, and `abbrev_state`.

## Examples

``` r
hi_search("MOSSORO")
#>     code_muni name_muni abbrev_state
#> 500   2408003   MOSSORO           RN
hi_search("CABROBO", state = "PE")
#>     code_muni name_muni abbrev_state
#> 811   2603009   CABROBO           PE
```
