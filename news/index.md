# Changelog

## avesperu 0.1.1

CRAN release: 2026-03-27

- Updated the bundled current checklist to `aves_peru_2026_v1`,
  reflecting the UNOP checklist version dated March 23, 2026.
- [`search_avesperu()`](https://paulesantos.github.io/avesperu/reference/search_avesperu.md)
  now uses exact matching before fuzzy edit-distance matching with
  `stringdist`, improving performance while preserving the existing
  input and output structure.
