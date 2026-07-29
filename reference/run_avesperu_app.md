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

## Examples

``` r
if (interactive()) {
  run_avesperu_app()
}
```
