# Approximate matching of scientific names

This vignette explains how
[`search_avesperu()`](https://paulesantos.github.io/avesperu/reference/search_avesperu.md)
handles likely spelling variants in submitted scientific names. Start
with a conservative threshold and review every non-exact match before
using it in an analysis.

## Requirements

All examples use the local checklist bundled with `avesperu`; they do
not call external services.

## Match a short list with spelling variants

``` r

submitted <- c("Falco sparverius", "Tinamus osgodi", "Crypturellus sooui", "Penelope albipenis")
matches <- search_avesperu(submitted, max_distance = 0.05, return_details = TRUE)
matches[, c("name_submitted", "accepted_name", "dist")]
#>       name_submitted       accepted_name dist
#> 1   Falco sparverius    Falco sparverius    0
#> 2     Tinamus osgodi     Tinamus osgoodi    1
#> 3 Crypturellus sooui   Crypturellus soui    1
#> 4 Penelope albipenis Penelope albipennis    1
```

`dist` is the edit distance between a submitted value and its candidate.
A value of zero denotes an exact match; values above zero require
review.

## Choose a threshold

`max_distance` accepts either a proportion between zero and one or a
nonnegative integer. A proportion scales with name length, while an
integer sets an absolute number of character edits.

``` r

# Exact matching only
search_avesperu(submitted, max_distance = 0, return_details = TRUE)

# Allow up to one character edit
search_avesperu(submitted, max_distance = 1, return_details = TRUE)

# Allow 10% of the name length
search_avesperu(submitted, max_distance = 0.1, return_details = TRUE)
```

## Escalate carefully

First identify names that remain unmatched, then retry only those rows
using a documented threshold. Preserve the original submission and
inspect each suggested match before updating source data.

``` r

strict <- search_avesperu(submitted, max_distance = 0, return_details = TRUE)
unmatched <- strict$name_submitted[is.na(strict$accepted_name)]
retry <- search_avesperu(unmatched, max_distance = 0.1, return_details = TRUE)
```

## Next steps

See [advanced
use](https://paulesantos.github.io/avesperu/articles/uso-avanzado.html)
for a field-data workflow and the [function
reference](https://paulesantos.github.io/avesperu/reference/search_avesperu.html)
for all arguments.
