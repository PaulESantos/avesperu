
<!-- README.md is generated from README.Rmd. Please edit that file -->

# avesperu <a href='https://github.com/PaulESantos/avesperu'><img src='man/figures/avesperu.svg' align="right" height="250" width="220" /></a>

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-green.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN
status](https://www.r-pkg.org/badges/version/avesperu)](https://CRAN.R-project.org/package=avesperu)
[![R-CMD-check](https://github.com/PaulESantos/avesperu/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/PaulESantos/avesperu/actions/workflows/R-CMD-check.yaml)
[![](http://cranlogs.r-pkg.org/badges/grand-total/avesperu?color=green)](https://cran.r-project.org/package=avesperu)
[![](http://cranlogs.r-pkg.org/badges/last-week/avesperu?color=green)](https://cran.r-project.org/package=avesperu)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

The `avesperu` package provides access to the most up-to-date and
comprehensive dataset on Peru’s avian diversity. As of **December 2,
2024**, the list includes **1,909 bird species**, reflecting significant
advancements in taxonomy and the validation of species records. These
updates are based on articles, photographs, and sound recordings
archived in accredited institutions, and follow the classification
endorsed by the **South American Checklist Committee (SACC)**.

### Species Categories

Each species in the dataset is classified into one of the following
categories, reflecting its status in Peru:

- **X (Resident)**: 1,542 species  
- **E (Endemic)**: 117 species  
- **NB (Migratory)**: 138 species  
- **V (Vagrant)**: 83 species  
- **IN (Introduced)**: 3 species  
- **EX (Extirpated)**: 0 species  
- **H (Hypothetical)**: 26 species

This results in a total of **1,909 species**, demonstrating Peru’s
incredible avian richness.

The `avesperu` package is designed to streamline access to this data for
researchers, conservationists, and bird enthusiasts alike, providing
tools for taxonomy validation and species data retrieval using advanced
fuzzy matching capabilities.

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

Here’s an enhanced analysis of the provided information, focusing on the
trends and implications for Peru’s avian biodiversity:

- The chart depicts the steady increase in the number of bird species
  recorded in Peru from 1968 to 2024, showcasing the country’s
  remarkable progress in avian taxonomy and biodiversity documentation.
  Over the decades, several key trends emerge:

### Significant Milestones:

The species count grew substantially between 1968 (1,491 species) and
1980 (1,678 species), reflecting early efforts in exploration and
classification. Post-2000, the growth rate appears more stable, with key
updates in 2010, 2020, and culminating in 2024 with 1,909 species.

### Categorical Analysis:

- Most of the species belong to the “Resident” (X) category, accounting
  for **1,542 species**, while **117 species** are classified as
  **endemic,** showcasing Peru’s unique biodiversity.

- Hypothetical species (“H”) contribute 26 species, emphasizing the
  importance of continued validation efforts to solidify their inclusion
  in the list.

## Suggested citation:

``` r
citation("avesperu")
#> To cite avesperu in publications use:
#> 
#>   Santos - Andrade, PE. (2024). avesperu: Access to the List of Birds
#>   Species of Peru. R package version 0.0.3
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {avesperu: Access to the List of Birds Species of Peru},
#>     author = {Paul E. Santos - Andrade},
#>     year = {2024},
#>     note = {R package version 0.0.3},
#>   }
#> 
#> To cite the avesperu dataset, please use: Plenge, M. A. Version
#> [12/02/2024] List of the birds of Peru / Lista de las aves del Perú.
#> Unión de Ornitólogos del Perú:
#> https://sites.google.com/site/boletinunop/checklist
```

## Installation

You can install the `avesperu` package from CRAN using:

``` r
install.packages("avesperu")
# or
pak::pak("avesperu")
```

Also you can install the development version of `avesperu` like so:

``` r
pak::pak("PaulESantos/avesperu")
```

## Usage

Here’s a quick example of how to use the `avesperu` package:

``` r
library(avesperu)
#> This is avesperu 0.0.3

splist <- c("Falco sparverius",
            "Tinamus osgodi",
            "Crypturellus sooui",
            "Thraupisa palamarum",
            "Thamnophilus praecox")

search_avesperu(splist = splist, max_distance = 0.05)
#>         name_submitted        accepted_name    order_name    family_name
#> 1     Falco sparverius     Falco sparverius Falconiformes     Falconidae
#> 2       Tinamus osgodi      Tinamus osgoodi  Tinamiformes      Tinamidae
#> 3   Crypturellus sooui    Crypturellus soui  Tinamiformes      Tinamidae
#> 4  Thraupisa palamarum                 <NA>          <NA>           <NA>
#> 5 Thamnophilus praecox Thamnophilus praecox Passeriformes Thamnophilidae
#>       english_name        spanish_name    status dist
#> 1 American Kestrel Cernícalo Americano Residente    0
#> 2    Black Tinamou        Perdiz Negra Residente    1
#> 3   Little Tinamou        Perdiz Chica Residente    1
#> 4             <NA>                <NA>      <NA> <NA>
#> 5  Cocha Antshrike     Batará de Cocha Residente    0
```

- The package not only provides access to the list of bird species
  recorded in Peru but also excels in resolving potential typos or
  variations in species names through fuzzy matching. It ensures
  accurate retrieval by intelligently recognizing and accommodating
  slight discrepancies in the input names, making it a robust tool for
  working with diverse and sometimes inconsistent datasets.

``` r
splist <- c("Falco sparverius",
            "Tinamus osgodi",
            "Crypturellus sooui",
            "Thraupisa palamarum",
            "Thraupisa palamarum",
            "Thamnophilus praecox")

search_avesperu(splist = splist, max_distance = 0.05)
#> The following names are repeated in the 'splist': Thraupisa palamarum
#>         name_submitted        accepted_name    order_name    family_name
#> 1     Falco sparverius     Falco sparverius Falconiformes     Falconidae
#> 2       Tinamus osgodi      Tinamus osgoodi  Tinamiformes      Tinamidae
#> 3   Crypturellus sooui    Crypturellus soui  Tinamiformes      Tinamidae
#> 4  Thraupisa palamarum                 <NA>          <NA>           <NA>
#> 5 Thamnophilus praecox Thamnophilus praecox Passeriformes Thamnophilidae
#>       english_name        spanish_name    status dist
#> 1 American Kestrel Cernícalo Americano Residente    0
#> 2    Black Tinamou        Perdiz Negra Residente    1
#> 3   Little Tinamou        Perdiz Chica Residente    1
#> 4             <NA>                <NA>      <NA> <NA>
#> 5  Cocha Antshrike     Batará de Cocha Residente    0
```
