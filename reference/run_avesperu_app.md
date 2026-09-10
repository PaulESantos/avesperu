# Run a TNRS-style Shiny app for avesperu

Launches an interactive Shiny application for batch resolution of bird
scientific names against the `avesperu` checklist. The interface is
inspired by the BIEN TNRS workflow, but uses the local `avesperu`
dataset and matching engine.

## Usage

``` r
run_avesperu_app(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive()
)
```

## Arguments

- host:

  Host interface passed to
  [`shiny::runApp`](https://rdrr.io/pkg/shiny/man/runApp.html). Default:
  `"127.0.0.1"`.

- port:

  Port passed to
  [`shiny::runApp`](https://rdrr.io/pkg/shiny/man/runApp.html). Default:
  `NULL` (Shiny selects a free port).

- launch.browser:

  Logical; passed to
  [`shiny::runApp`](https://rdrr.io/pkg/shiny/man/runApp.html). Default:
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

## Value

The value returned by
[`shiny::runApp`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Details

The app supports:

- Batch input via pasted text or uploaded CSV/TXT/TSV files

- Name parsing and standardization

- Exact or fuzzy matching through
  [`search_avesperu`](https://paulesantos.github.io/avesperu/reference/search_avesperu.md)

- Interactive review of matches and export of results and metadata

Synonym retrieval is not currently available because `avesperu` ships
the accepted Peru checklist, not a synonymy backbone.

Resolution runs in a separate R process using `callr` and `later`. Each
session has at most one active job; changing inputs, clearing, or
closing the session cancels it. Closing a session does not stop the
shared application process. Runs accept at most 10,000 names, 200
characters per name and four cores. Imports preserve source records and
missing values. Standard column headers are recognized automatically;
other layouts require header/column selection. CSV/TSV source rows are
record numbers, not physical lines for quoted multiline fields. Excel
rows refer to worksheet rows. Downloads require a completed run for the
current inputs and include review reasons and reference provenance.

## Examples

``` r
if (interactive()) {
  run_avesperu_app()
}
```
