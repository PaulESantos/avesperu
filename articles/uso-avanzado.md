# Advanced use of avesperu

This vignette shows how to add current Peru-checklist information to a
small set of field observations while preserving the submitted names for
review.

## Requirements

The examples use only data bundled with `avesperu`.

## Validate a field list

``` r

field_data <- data.frame(observer = c("Observer A", "Observer B", "Observer A", "Observer C"), species = c("Amazilia amazilia", "Phaetornis guy", "Metallura tyrianthina", "Tangara chilensis"), count = c(2, 1, 3, 5))
details <- search_avesperu(field_data$species, return_details = TRUE)
field_data$accepted_name <- details$accepted_name
field_data$status <- details$status
field_data$family <- details$family_name
field_data
#>     observer               species count         accepted_name    status
#> 1 Observer A     Amazilia amazilia     2     Amazilis amazilia Residente
#> 2 Observer B        Phaetornis guy     1       Phaethornis guy Residente
#> 3 Observer A Metallura tyrianthina     3 Metallura tyrianthina Residente
#> 4 Observer C     Tangara chilensis     5     Tangara chilensis Residente
#>        family
#> 1 Trochilidae
#> 2 Trochilidae
#> 3 Trochilidae
#> 4  Thraupidae
```

Expected result: each submitted name remains associated with its
accepted name, status, and family. Rows without an accepted name need
manual review.

## Identify endemic species

``` r

my_species <- c("Penelope albipennis", "Xenoglaux loweryi", "Falco sparverius")
results <- search_avesperu(my_species, return_details = TRUE)
results[results$status == "Endémico", c("accepted_name", "english_name", "family_name")]
#>         accepted_name         english_name family_name
#> 1 Penelope albipennis    White-winged Guan    Cracidae
#> 2   Xenoglaux loweryi Long-whiskered Owlet   Strigidae
```

This pattern is useful for filtering a submitted list, not for replacing
a project-specific definition of endemism.

## Review uncertain results

Qualified and hybrid inputs, as well as tied candidates, are retained
for review. Detailed output includes audit attributes that describe
reconciliation, execution, and the checklist reference.

``` r

result <- search_avesperu("Falco CF. sparverius", return_details = TRUE)
attr(result, "reconciliation")
#>         submitted_name standardized_name has_qualifier has_hybrid match_type
#> 1 Falco CF. sparverius  Falco sparverius          TRUE      FALSE      exact
#>   candidate_count       candidates review_reason review_flag
#> 1               1 Falco sparverius     qualifier        TRUE
attr(result, "execution")
#> $mode
#> [1] "sequential"
#> 
#> $workers
#> [1] 1
#> 
#> $batches
#> [1] 1
#> 
#> $fallback
#> [1] NA
attr(result, "reference")
#> $id
#> [1] "aves_peru_2026_v1"
#> 
#> $content_md5
#> [1] "46385e0a8934db6c2b2a8e1e407e1461"
#> 
#> $version_date
#> [1] "23 de marzo de 2026"
#> 
#> $source_url
#> [1] "https://sites.google.com/site/boletinunop/checklist"
#> 
#> $package_version
#> [1] "0.1.1.9000"
```

## Next steps

Use [approximate
matching](https://paulesantos.github.io/avesperu/articles/coincidencia-aproximada.html)
for spelling variants, or inspect the [reference
documentation](https://paulesantos.github.io/avesperu/reference/index.html)
for complete function arguments.
