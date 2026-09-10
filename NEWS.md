# avesperu (development version)

- `aves_peru_2026_v1` now keeps genus and epithet consistent with the scientific-name key and preserves the original two discrepancies in `component_corrections` (reference validation follow-up).
- `run_avesperu_app()` preserves source rows during import, supports explicit header/column selection and previews, exports review reasons and actual execution provenance, invalidates stale results, closes only the current session, and resolves bounded workloads in cancellable background processes (H01, H02, H04, H05, H11).
- `search_avesperu()` reports ties as ambiguous instead of selecting by row order. Detailed output keeps its eight columns and adds `reconciliation`, `execution` and `reference` attributes; qualified/hybrid inputs require review and return NA in the basic status vector (H02, H03).
- `search_avesperu()` validates finite scalar options and integer counts, normalizes qualifiers consistently, returns typed empty results, and applies sequential batches. Parallel workers use the running source and failures record their sequential fallback (H06–H10).
- `unop_check_update()` tolerates one-digit days, case/spacing differences and multiple labelled update dates (UNOP parser follow-up).

# avesperu 0.1.1

- Updated the bundled current checklist to `aves_peru_2026_v1`, reflecting the UNOP checklist version dated March 23, 2026.
- `search_avesperu()` now uses exact matching before fuzzy edit-distance matching with `stringdist`, improving performance while preserving the existing input and output structure.

