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
#>       name_submitted    accepted_name    order_name family_name
#> 1   Falco sparverius Falco sparverius Falconiformes  Falconidae
#> 2     Tinamus osgodi             <NA>          <NA>        <NA>
#> 3 Crypturellus sooui             <NA>          <NA>        <NA>
#> 4 Penelope albipenis             <NA>          <NA>        <NA>
#>       english_name        spanish_name    status dist
#> 1 American Kestrel Cernícalo Americano Residente    0
#> 2             <NA>                <NA>      <NA> <NA>
#> 3             <NA>                <NA>      <NA> <NA>
#> 4             <NA>                <NA>      <NA> <NA>

# Allow up to one character edit
search_avesperu(submitted, max_distance = 1, return_details = TRUE)
#>       name_submitted       accepted_name    order_name family_name
#> 1   Falco sparverius    Falco sparverius Falconiformes  Falconidae
#> 2     Tinamus osgodi     Tinamus osgoodi  Tinamiformes   Tinamidae
#> 3 Crypturellus sooui   Crypturellus soui  Tinamiformes   Tinamidae
#> 4 Penelope albipenis Penelope albipennis   Galliformes    Cracidae
#>        english_name        spanish_name    status dist
#> 1  American Kestrel Cernícalo Americano Residente    0
#> 2     Black Tinamou        Perdiz Negra Residente    1
#> 3    Little Tinamou        Perdiz Chica Residente    1
#> 4 White-winged Guan  Pava de Ala Blanca  Endémico    1

# Allow 10% of the name length
search_avesperu(submitted, max_distance = 0.1, return_details = TRUE)
#>       name_submitted       accepted_name    order_name family_name
#> 1   Falco sparverius    Falco sparverius Falconiformes  Falconidae
#> 2     Tinamus osgodi     Tinamus osgoodi  Tinamiformes   Tinamidae
#> 3 Crypturellus sooui   Crypturellus soui  Tinamiformes   Tinamidae
#> 4 Penelope albipenis Penelope albipennis   Galliformes    Cracidae
#>        english_name        spanish_name    status dist
#> 1  American Kestrel Cernícalo Americano Residente    0
#> 2     Black Tinamou        Perdiz Negra Residente    1
#> 3    Little Tinamou        Perdiz Chica Residente    1
#> 4 White-winged Guan  Pava de Ala Blanca  Endémico    1
```

## Escalate carefully

First identify names that remain unmatched, then retry only those rows
using a documented threshold. Preserve the original submission and
inspect each suggested match before updating source data.

``` r

strict <- search_avesperu(submitted, max_distance = 0, return_details = TRUE)
strict
#>       name_submitted    accepted_name    order_name family_name
#> 1   Falco sparverius Falco sparverius Falconiformes  Falconidae
#> 2     Tinamus osgodi             <NA>          <NA>        <NA>
#> 3 Crypturellus sooui             <NA>          <NA>        <NA>
#> 4 Penelope albipenis             <NA>          <NA>        <NA>
#>       english_name        spanish_name    status dist
#> 1 American Kestrel Cernícalo Americano Residente    0
#> 2             <NA>                <NA>      <NA> <NA>
#> 3             <NA>                <NA>      <NA> <NA>
#> 4             <NA>                <NA>      <NA> <NA>

unmatched <- strict$name_submitted[is.na(strict$accepted_name)]
unmatched
#> [1] "Tinamus osgodi"     "Crypturellus sooui" "Penelope albipenis"

retry <- search_avesperu(unmatched, max_distance = 0.1, return_details = TRUE)
retry
#>       name_submitted       accepted_name   order_name family_name
#> 1     Tinamus osgodi     Tinamus osgoodi Tinamiformes   Tinamidae
#> 2 Crypturellus sooui   Crypturellus soui Tinamiformes   Tinamidae
#> 3 Penelope albipenis Penelope albipennis  Galliformes    Cracidae
#>        english_name       spanish_name    status dist
#> 1     Black Tinamou       Perdiz Negra Residente    1
#> 2    Little Tinamou       Perdiz Chica Residente    1
#> 3 White-winged Guan Pava de Ala Blanca  Endémico    1
```

## Next steps

See [advanced
use](https://paulesantos.github.io/avesperu/articles/uso-avanzado.html)
for a field-data workflow and the [function
reference](https://paulesantos.github.io/avesperu/reference/search_avesperu.html)
for all arguments.
