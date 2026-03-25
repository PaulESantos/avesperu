# Comparison between aves_peru_2025_v5 and aves_peru_2026_v1

## Introduction

This vignette highlights the differences and updates between the
previous dataset `aves_peru_2025_v5` and the newly released dataset
`aves_peru_2026_v1` in the `avesperu` package.

``` r
library(avesperu)
```

## Summary Comparison

Let’s compare the total number of species and the distribution of their
statuses.

``` r
# 2025 version
table(aves_peru_2025_v5$status)
#> 
#>     Divagante      Endémico   Introducido    Migratorio No confirmado 
#>            86           118             3           140            23 
#>     Residente 
#>          1549

# 2026 version
table(aves_peru_2026_v1$status)
#> 
#>     Divagante      Endémico   Introducido    Migratorio No confirmado 
#>            90           119             3           140            21 
#>     Residente 
#>          1552
```

## Additions and Removals

Identify the species that were added or removed in the 2026 update.

``` r
added_species <- setdiff(aves_peru_2026_v1$scientific_name, aves_peru_2025_v5$scientific_name)
removed_species <- setdiff(aves_peru_2025_v5$scientific_name, aves_peru_2026_v1$scientific_name)

length(added_species)
#> [1] 9
length(removed_species)
#> [1] 3

# Display some newly added species
head(added_species)
#> [1] "Columbina squammata"         "Fulica americana"           
#> [3] "Anous stolidus"              "Camptostoma sclateri"       
#> [5] "Camptostoma napaeum"         "Tunchiornis ferrugineifrons"
```

## Taxonomic Changes

Check if any families or orders have updated species counts or
additions.

``` r
# 2025 Families count
length(unique(aves_peru_2025_v5$family_name))
#> [1] 90

# 2026 Families count
length(unique(aves_peru_2026_v1$family_name))
#> [1] 91
```

This ensures users can easily transition their workflows and verify
taxonomic consistency between these iterations.
