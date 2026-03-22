# Check whether the local dataset is up to date against UNOP

This function compares the local dataset version date stored in
`aves_peru_2025_v5` against the latest update date published on the UNOP
checklist website. It is designed to be called explicitly by the user,
or enabled through the `avesperu.check_updates` option.

## Usage

``` r
unop_check_update(verbose = interactive())
```

## Arguments

- verbose:

  Logical. If `TRUE`, prints a summary with `cli` alerts. If `FALSE`,
  returns the result silently. Default:
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

## Value

An invisible named list with the fields `success`, `is_up_to_date`,
`has_update`, `current_version_date`, `online_version_date`,
`checked_at`, `source_url`, and `message`.
