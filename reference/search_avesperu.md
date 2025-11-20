# Search for Bird Species Data in the Birds of Peru Dataset

This function searches for bird species information in the dataset
provided by the `avesperu` package, given a list of species names. It
supports approximate (fuzzy) matching to handle typographical errors or
minor variations in species names using optimized
[`agrep()`](https://rdrr.io/r/base/agrep.html) matching. The function is
optimized for both small and large lists through intelligent
pre-filtering and optional parallel processing, while maintaining exact
[`agrep()`](https://rdrr.io/r/base/agrep.html) precision.

## Usage

``` r
search_avesperu(
  splist,
  max_distance = 0.1,
  return_details = FALSE,
  batch_size = 100,
  parallel = TRUE,
  n_cores = NULL
)
```

## Arguments

- splist:

  A character vector or factor containing the scientific names of bird
  species to search for. Names can include minor variations or typos.

- max_distance:

  Numeric. The maximum allowable distance for fuzzy matching. Can be
  either:

  - A proportion between 0 and 1 (e.g., 0.1 = 10\\

  - An integer representing the maximum number of character differences

  Default: 0.1.

- return_details:

  Logical. If `FALSE` (default), returns only a character vector of
  species status. If `TRUE`, returns a detailed data frame with complete
  reconciliation information including taxonomic data and matching
  distances.

- batch_size:

  Integer. Number of species to process per batch when handling large
  lists. Useful for memory management and progress tracking. Default:
  100 species per batch.

- parallel:

  Logical. Should parallel processing be used for large lists?
  Automatically disabled for small lists. Requires the `parallel`
  package. Default: `TRUE`.

- n_cores:

  Integer or `NULL`. Number of CPU cores to use for parallel processing.
  If `NULL` (default), uses `detectCores() - 1` to leave one core free
  for system operations.

## Value

The return value depends on the `return_details` parameter:

**If return_details = FALSE (default):**

A character vector with the same length as `splist`, containing the
conservation/occurrence status for each species. `NA` values indicate no
match was found.

**If return_details = TRUE:**

A data frame (tibble-compatible) with the following columns:

- name_submitted:

  Character. The species name provided as input (standardized).

- accepted_name:

  Character. The closest matching species name from the database, or
  `NA` if no match found within `max_distance`.

- order_name:

  Character. The taxonomic order of the matched species.

- family_name:

  Character. The taxonomic family of the matched species.

- english_name:

  Character. Common name in English.

- spanish_name:

  Character. Common name in Spanish.

- status:

  Character. Conservation or occurrence status (e.g., "Endemic",
  "Resident", "Migrant", "Vagrant").

- dist:

  Character. Edit distance between submitted and matched names. Lower
  values indicate better matches. `NA` if no match found.

## Details

The function performs the following steps:

1.  Validates input and converts factors to character vectors

2.  Standardizes species names using
    [`standardize_names()`](https://paulesantos.github.io/avesperu/reference/standardize_names.md)

3.  Identifies and reports duplicate entries in the input list

4.  Uses intelligent pre-filtering to reduce search space:

    - Filters by string length (mathematically guaranteed to preserve
      matches)

    - Optionally filters by first character for very large candidate
      sets

5.  Performs precise [`agrep()`](https://rdrr.io/r/base/agrep.html)
    fuzzy matching on filtered candidates

6.  Calculates exact edit distances using
    [`adist()`](https://rdrr.io/r/utils/adist.html)

7.  Selects the best match (minimum distance) for each query

8.  For large lists (\>batch_size), processes in batches with optional
    parallelization

## Warning

For very large lists (\>10,000 species) with parallel processing
enabled, ensure sufficient system memory is available. Each parallel
worker maintains a copy of the reference database (~5-10 MB).

## See also

[`agrep`](https://rdrr.io/r/base/agrep.html) for the underlying fuzzy
matching algorithm

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage - returns status vector
splist <- c("Falco sparverius", "Tinamus osgodi", "Crypturellus soui")
status <- search_avesperu(splist)
print(status)

# Get detailed reconciliation information
details <- search_avesperu(splist, return_details = TRUE)
print(details)

# Exact matching only (no fuzzy matching)
exact_results <- search_avesperu(splist, max_distance = 0)

# Handle species with typos
typo_list <- c("Falco sparveruis", "Tinamus osgoodi", "Crypturellus sui")
corrected <- search_avesperu(typo_list, return_details = TRUE)

# View submitted vs accepted names
print(corrected[, c("name_submitted", "accepted_name", "dist")])

} # }
```
