#' Run a TNRS-style Shiny app for avesperu
#'
#' Launches an interactive Shiny application for batch resolution of bird
#' scientific names against the `avesperu` checklist. The interface is inspired
#' by the BIEN TNRS workflow, but uses the local `avesperu` dataset and matching
#' engine.
#'
#' The app supports:
#' \itemize{
#'   \item Batch input via pasted text or uploaded CSV/TXT/TSV files
#'   \item Name parsing and standardization
#'   \item Exact or fuzzy matching through \code{\link{search_avesperu}}
#'   \item Interactive review of matches and export of results and metadata
#' }
#'
#' Synonym retrieval is not currently available because `avesperu` ships the
#' accepted Peru checklist, not a synonymy backbone.
#'
#' @param host Host interface passed to \code{\link[shiny:runApp]{shiny::runApp}}.
#'   Default: `"127.0.0.1"`.
#' @param port Port passed to \code{\link[shiny:runApp]{shiny::runApp}}.
#'   Default: `NULL` (Shiny selects a free port).
#' @param launch.browser Logical; passed to
#'   \code{\link[shiny:runApp]{shiny::runApp}}. Default: `interactive()`.
#'
#' @details
#' Resolution runs in a separate R process using `callr` and `later`. Each session
#' has at most one active job; changing inputs, clearing, or closing the session
#' cancels it. Closing a session does not stop the shared application process.
#' Runs accept at most 10,000 names, 200 characters per name and four cores.
#' Imports preserve source records and missing values. Standard column headers
#' are recognized automatically; other layouts require header/column selection.
#' CSV/TSV source rows are record numbers, not physical lines for quoted multiline
#' fields. Excel rows refer to worksheet rows. Downloads require a completed run
#' for the current inputs and include review reasons and reference provenance.
#'
#' @return The value returned by \code{\link[shiny:runApp]{shiny::runApp}}.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   run_avesperu_app()
#' }
run_avesperu_app <- function(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive()
) {
  check_avesperu_app_deps()

  shiny::runApp(
    shiny::shinyApp(ui = avesperu_app_ui(), server = avesperu_app_server),
    host = host,
    port = port,
    launch.browser = launch.browser
  )
}

#' @keywords internal
check_avesperu_app_deps <- function() {
  missing_pkgs <- c("shiny", "DT", "callr", "later")
  missing_pkgs <- missing_pkgs[
    !vapply(
      missing_pkgs,
      requireNamespace,
      quietly = TRUE,
      FUN.VALUE = logical(1)
    )
  ]

  if (length(missing_pkgs) > 0) {
    cli::cli_abort(
      "To run the Shiny app, install these packages first: {.pkg {missing_pkgs}}",
      call = parent.frame()
    )
  }
}

#' @keywords internal
check_avesperu_xlsx_dep <- function() {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    cli::cli_abort(
      "To download XLSX files, install the {.pkg writexl} package first.",
      call = parent.frame()
    )
  }
}

#' @keywords internal
check_avesperu_excel_read_dep <- function() {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(
      "To upload Excel files, install the {.pkg readxl} package first.",
      call = parent.frame()
    )
  }
}

#' @keywords internal
split_submitted_names <- function(text) {
  if (length(text) == 0 || is.na(text) || !nzchar(text)) {
    return(character(0))
  }

  lines <- unlist(strsplit(text, "\r\n|\n|\r", perl = TRUE), use.names = FALSE)
  lines <- trimws(lines)
  lines[nzchar(lines)]
}

#' @keywords internal
guess_name_column <- function(x) {
  if (!is.data.frame(x) || ncol(x) == 0) {
    return(NULL)
  }

  nm <- tolower(names(x))
  preferred <- c(
    "scientific_name",
    "submitted_name",
    "species",
    "species_name",
    "taxon",
    "taxon_name",
    "name"
  )

  exact_hit <- match(preferred, nm, nomatch = 0L)
  exact_hit <- exact_hit[exact_hit > 0L]
  if (length(exact_hit) > 0L) {
    return(exact_hit[1])
  }

  pattern_hit <- grep("scientific|species|taxon|name", nm)
  if (length(pattern_hit) > 0L) {
    return(pattern_hit[1])
  }

  1L
}

#' @keywords internal
read_avesperu_name_file <- function(
  path,
  filename = basename(path),
  header = "auto",
  column = NULL,
  records = FALSE
) {
  ext <- tolower(tools::file_ext(filename))
  if (!header %in% c("auto", "yes", "no")) {
    cli::cli_abort("Invalid header selection.")
  }
  if (ext %in% c("txt", "lst")) {
    values <- readLines(path, warn = FALSE, encoding = "UTF-8")
    out <- data.frame(
      stringsAsFactors = FALSE,
      submitted_name = trimws(values),
      source_file = rep(filename, length(values)),
      source_row = seq_along(values)
    )
  } else {
    if (ext %in% c("xlsx", "xls")) {
      check_avesperu_excel_read_dep()
      tbl <- as.data.frame(readxl::read_excel(
        path,
        col_names = FALSE,
        col_types = "text",
        range = readxl::cell_limits(c(1, 1), c(NA, NA))
      ))
    } else if (ext %in% c("csv", "tsv")) {
      tbl <- utils::read.table(
        path,
        header = FALSE,
        sep = if (ext == "tsv") "\t" else ",",
        quote = "\"",
        comment.char = "",
        colClasses = "character",
        fill = TRUE,
        blank.lines.skip = FALSE,
        check.names = FALSE,
        fileEncoding = "UTF-8-BOM",
        na.strings = "NA"
      )
    } else {
      cli::cli_abort(
        "Only CSV, TSV, TXT, and Excel uploads are currently supported."
      )
    }
    if (!ncol(tbl) || !nrow(tbl)) {
      cli::cli_abort("The uploaded file contains no rows.")
    }
    first <- tolower(trimws(unlist(tbl[1, ], use.names = FALSE)))
    known <- c(
      "scientific_name",
      "submitted_name",
      "species",
      "species_name",
      "taxon",
      "taxon_name",
      "name"
    )
    detected <- which(first %in% known)
    has_header <- if (header == "auto") {
      length(detected) > 0
    } else {
      header == "yes"
    }
    if (is.null(column) || identical(column, "auto")) {
      if (length(detected) == 1L && has_header) {
        column <- detected
      } else if (ncol(tbl) == 1L) {
        column <- 1L
      } else {
        cli::cli_abort(
          "Select the scientific-name column number and whether the file has a header.",
          preview = utils::head(tbl, 10)
        )
      }
    }
    column <- suppressWarnings(as.numeric(column))
    if (!is_count(column) || column > ncol(tbl)) {
      cli::cli_abort("Select an existing column number.")
    }
    rows <- seq_len(nrow(tbl))
    if (has_header) {
      rows <- rows[-1L]
    }
    values <- tbl[[column]][rows]
    values[!is.na(values)] <- trimws(values[!is.na(values)])
    out <- data.frame(
      stringsAsFactors = FALSE,
      submitted_name = values,
      source_file = rep(filename, length(rows)),
      source_row = rows
    )
  }
  if (records) out else out$submitted_name
}

extract_name_parts <- function(x) {
  empty <- data.frame(
    stringsAsFactors = FALSE,
    submitted_genus = character(),
    submitted_species_epithet = character(),
    submitted_infraspecific = character(),
    submitted_author = character(),
    submitted_unparsed = character(),
    submitted_rank_guess = character()
  )
  if (!length(x)) {
    return(empty)
  }
  rows <- lapply(as.character(x), function(name) {
    if (is.na(name)) {
      name <- ""
    }
    tokens <- strsplit(trimws(gsub("_", " ", name, fixed = TRUE)), "\\s+")[[1]]
    tokens <- tokens[!tolower(tokens) %in% c("cf.", "aff.", "x", "\u00d7")]
    tokens <- tokens[nzchar(tokens)]
    genus <- if (length(tokens)) standardize_names(tokens[1]) else NA_character_
    epithet <- if (length(tokens) >= 2L) tolower(tokens[2]) else NA_character_
    infra <- author <- unparsed <- NA_character_
    rank <- if (!length(tokens)) {
      "empty"
    } else if (length(tokens) == 1L) {
      "uninomial"
    } else {
      "binomial"
    }
    if (length(tokens) > 2L) {
      rest <- tokens[-c(1, 2)]
      text <- paste(rest, collapse = " ")
      # Authors require a year; unknown trailing text remains explicitly unparsed.
      if (grepl("^[[:alpha:](].*[, ]+[12][0-9]{3}\\)?$", text)) {
        author <- text
      } else if (length(rest) == 1L && grepl("^[a-z][a-z-]+$", rest)) {
        infra <- rest
        rank <- "infraspecific"
      } else if (
        length(rest) == 2L &&
          tolower(rest[1]) %in% c("subsp.", "ssp.", "var.", "f.") &&
          grepl("^[a-z][a-z-]+$", rest[2])
      ) {
        infra <- rest[2]
        rank <- "infraspecific"
      } else {
        unparsed <- text
        rank <- "unparsed"
      }
    }
    data.frame(
      stringsAsFactors = FALSE,
      submitted_genus = genus,
      submitted_species_epithet = epithet,
      submitted_infraspecific = infra,
      submitted_author = author,
      submitted_unparsed = unparsed,
      submitted_rank_guess = rank
    )
  })
  do.call(rbind, rows)
}

#' @keywords internal
flag_duplicate_names <- function(x) {
  duplicated(x) | duplicated(x, fromLast = TRUE)
}

#' @keywords internal
build_parse_results <- function(splist) {
  normalized <- normalize_name_records(splist)
  parts <- extract_name_parts(splist)
  reason <- ifelse(
    normalized$has_hybrid,
    "hybrid",
    ifelse(normalized$has_qualifier, "qualifier", "")
  )
  invalid <- parts$submitted_rank_guess %in% c("empty", "uninomial", "unparsed")
  reason[invalid] <- ifelse(
    nzchar(reason[invalid]),
    paste(reason[invalid], "unparsed", sep = ";"),
    "unparsed"
  )
  data.frame(
    stringsAsFactors = FALSE,
    input_order = seq_along(splist),
    normalized,
    parts,
    duplicate_input = flag_duplicate_names(normalized$standardized_name),
    review_flag = nzchar(reason),
    review_reason = reason
  )
}

build_resolution_results <- function(
  splist,
  max_distance = 0.1,
  batch_size = 250,
  parallel = FALSE,
  n_cores = NULL
) {
  resolved <- search_avesperu(
    splist,
    max_distance,
    TRUE,
    batch_size,
    parallel,
    n_cores
  )
  audit <- attr(resolved, "reconciliation")
  db <- current_checklist()
  matched <- db[
    match(resolved$accepted_name, db$scientific_name),
    ,
    drop = FALSE
  ]
  out <- data.frame(
    stringsAsFactors = FALSE,
    input_order = seq_along(splist),
    audit,
    extract_name_parts(splist),
    resolved[, -1, drop = FALSE],
    matched_genus = matched$genus,
    matched_species_epithet = matched$species_epithet,
    status_code = matched$status_code,
    edit_distance = as.integer(resolved$dist),
    duplicate_input = flag_duplicate_names(audit$standardized_name)
  )
  invalid <- out$submitted_rank_guess %in% c("empty", "uninomial", "unparsed")
  out$review_flag[invalid] <- TRUE
  out$review_reason[invalid] <- paste(
    out$review_reason[invalid],
    "unparsed",
    sep = ";"
  )
  attr(out, "execution") <- attr(resolved, "execution")
  attr(out, "reference") <- attr(resolved, "reference")
  out
}

#' @keywords internal
summarize_app_results <- function(results, mode = c("resolve", "parse")) {
  mode <- match.arg(mode)

  if (nrow(results) == 0) {
    return(data.frame(
      label = c("Submitted", "Unique"),
      value = c(0L, 0L),
      note = c("No names loaded", "No names loaded"),
      stringsAsFactors = FALSE
    ))
  }

  if (mode == "resolve") {
    data.frame(
      label = c(
        "Submitted",
        "Unique",
        "Exact",
        "Fuzzy",
        "Ambiguous",
        "Unmatched"
      ),
      value = c(
        nrow(results),
        length(unique(results$standardized_name)),
        sum(results$match_type == "exact", na.rm = TRUE),
        sum(results$match_type == "fuzzy", na.rm = TRUE),
        sum(results$match_type == "ambiguous", na.rm = TRUE),
        sum(results$match_type == "unmatched", na.rm = TRUE)
      ),
      note = c(
        "Rows processed",
        "Unique standardized names",
        "Distance = 0",
        "Review recommended",
        "Multiple best candidates",
        "No accepted name found"
      ),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(
      label = c("Submitted", "Unique", "Binomials", "Duplicates"),
      value = c(
        nrow(results),
        length(unique(results$standardized_name)),
        sum(results$submitted_rank_guess == "binomial", na.rm = TRUE),
        sum(results$duplicate_input, na.rm = TRUE)
      ),
      note = c(
        "Rows parsed",
        "Unique standardized names",
        "Genus + epithet",
        "Repeated standardized names"
      ),
      stringsAsFactors = FALSE
    )
  }
}

#' @keywords internal
build_app_metadata <- function(
  results,
  mode,
  max_distance,
  batch_size,
  parallel,
  n_cores,
  pasted_names,
  uploaded_names
) {
  metrics <- summarize_app_results(results, mode = mode)
  checklist_date <- attr(current_checklist(), "version_date", exact = TRUE)
  source_url <- "https://sites.google.com/site/boletinunop/checklist"

  metadata <- data.frame(
    field = c(
      "application",
      "package_version",
      "processing_mode",
      "matching_mode",
      "max_distance",
      "batch_size",
      "parallel",
      "n_cores",
      "pasted_names",
      "uploaded_names",
      "submitted_rows",
      "unique_standardized_names",
      "checklist_version_date",
      "checklist_source",
      "generated_at"
    ),
    value = c(
      "avesperu Resolver",
      as.character(utils::packageVersion("avesperu")),
      if (identical(mode, "resolve")) {
        "Perform Name Resolution"
      } else {
        "Parse Names Only"
      },
      if (identical(mode, "resolve") && isTRUE(max_distance == 0)) {
        "Exact only"
      } else if (identical(mode, "resolve")) {
        "Fuzzy matching"
      } else {
        NA_character_
      },
      if (identical(mode, "resolve")) {
        as.character(max_distance)
      } else {
        NA_character_
      },
      if (identical(mode, "resolve")) {
        as.character(batch_size)
      } else {
        NA_character_
      },
      if (identical(mode, "resolve")) as.character(parallel) else NA_character_,
      if (identical(mode, "resolve")) {
        if (is.null(n_cores)) "auto" else as.character(n_cores)
      } else {
        NA_character_
      },
      as.character(pasted_names),
      as.character(uploaded_names),
      as.character(metrics$value[metrics$label == "Submitted"][1]),
      as.character(metrics$value[metrics$label == "Unique"][1]),
      checklist_date,
      source_url,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
    ),
    stringsAsFactors = FALSE
  )
  execution <- attr(results, "execution")
  if (is.null(execution)) {
    execution <- list(
      mode = "parse",
      workers = 1L,
      batches = 1L,
      fallback = NA_character_
    )
  }
  reference <- attr(results, "reference")
  if (is.null(reference)) {
    reference <- checklist_metadata()
  }
  extra <- c(
    stats::setNames(execution, paste0("effective_", names(execution))),
    stats::setNames(reference, paste0("reference_", names(reference)))
  )
  rbind(
    metadata,
    data.frame(
      stringsAsFactors = FALSE,
      field = names(extra),
      value = vapply(extra, as.character, character(1))
    )
  )
}

#' @keywords internal
metric_cards_ui <- function(metrics) {
  cards <- lapply(seq_len(nrow(metrics)), function(i) {
    shiny::tags$div(
      class = "metric-card",
      shiny::tags$div(class = "metric-label", metrics$label[i]),
      shiny::tags$div(class = "metric-value", metrics$value[i]),
      shiny::tags$div(class = "metric-note", metrics$note[i])
    )
  })

  shiny::tags$div(class = "metric-grid", cards)
}

#' @keywords internal
avesperu_app_ui <- function() {
  checklist_date <- attr(current_checklist(), "version_date", exact = TRUE)

  shiny::fluidPage(
    title = "avesperu",
    shiny::tags$head(
      shiny::tags$script(shiny::HTML(
        "Shiny.addCustomMessageHandler('reset-upload', function(id) { var el = document.getElementById(id); if (el) { el.value = ''; var box = el.closest('.form-group'); if (box) { var text = box.querySelector('input[type=text]'); if (text) text.value = ''; } } Shiny.setInputValue(id, null, {priority: 'event'}); });"
      )),
      shiny::tags$style(shiny::HTML(
        "
        :root {
          --macaw-blue: #3559a6;
          --macaw-blue-dark: #2b4783;
          --macaw-teal: #4b807c;
          --macaw-sky: #67aae7;
          --macaw-sun: #f3d24f;
          --macaw-ink: #161616;
          --macaw-cream: #fffdf6;
          --macaw-mist: #eef7fd;
        }
        body {
          background: linear-gradient(180deg, var(--macaw-mist) 0%, #f8fbff 48%, #fff4c8 100%);
          color: #23262b;
          font-size: 15px;
        }
        .hero-shell {
          background: linear-gradient(135deg, #2e4f95 0%, var(--macaw-blue) 24%, var(--macaw-teal) 62%, var(--macaw-sky) 100%);
          border-radius: 20px;
          padding: 20px 24px;
          margin: 14px 0 16px 0;
          color: #fffdf8;
          box-shadow: 0 22px 48px rgba(43, 71, 131, 0.18);
        }
        .hero-layout {
          display: flex;
          flex-wrap: wrap;
          justify-content: space-between;
          align-items: flex-end;
          gap: 18px;
        }
        .hero-copy {
          flex: 1 1 920px;
          min-width: 280px;
        }
        .hero-meta {
          flex: 0 1 320px;
          min-width: 250px;
        }
        .hero-meta-card {
          background: rgba(255, 245, 198, 0.14);
          border: 1px solid rgba(255, 231, 142, 0.24);
          border-radius: 14px;
          padding: 12px 14px;
          backdrop-filter: blur(4px);
        }
        .hero-shell h1 {
          margin-top: 0;
          font-family: Georgia, 'Times New Roman', serif;
          font-size: 30px;
          font-weight: 700;
          letter-spacing: 0.02em;
          margin-bottom: 10px;
        }
        .hero-shell p {
          font-size: 15px;
          max-width: none;
          margin-bottom: 0;
          line-height: 1.45;
          white-space: nowrap;
        }
        @media (max-width: 1500px) {
          .hero-shell p {
            white-space: normal;
          }
        }
        .hero-kicker {
          text-transform: uppercase;
          letter-spacing: 0.16em;
          font-size: 11px;
          color: rgba(255, 243, 188, 0.96);
          margin-bottom: 10px;
        }
        .hero-meta-label {
          font-size: 10px;
          text-transform: uppercase;
          letter-spacing: 0.14em;
          opacity: 0.8;
          margin-bottom: 6px;
        }
        .hero-meta-line {
          font-size: 13px;
          line-height: 1.5;
        }
        .app-card {
          background: rgba(255, 255, 255, 0.88);
          border: 1px solid rgba(53, 89, 166, 0.10);
          border-radius: 16px;
          padding: 16px;
          margin-bottom: 14px;
          box-shadow: 0 14px 28px rgba(43, 71, 131, 0.08);
          backdrop-filter: blur(4px);
        }
        .app-card h3 {
          margin-top: 0;
          margin-bottom: 10px;
          font-family: Georgia, 'Times New Roman', serif;
          font-size: 22px;
        }
        .app-card p, .app-card li, .small-muted, .control-label, .radio label, .checkbox label {
          font-size: 13px;
          line-height: 1.4;
        }
        .form-group {
          margin-bottom: 10px;
        }
        .form-control {
          font-size: 13px;
        }
        textarea#names_text {
          height: 300px !important;
          min-height: 300px;
          max-height: 300px;
          resize: none;
          overflow-y: auto;
        }
        .metric-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
          gap: 10px;
        }
        .metric-card {
          background: var(--macaw-cream);
          border: 1px solid rgba(75, 128, 124, 0.18);
          border-radius: 14px;
          padding: 10px 12px;
        }
        .metric-label {
          font-size: 10px;
          text-transform: uppercase;
          letter-spacing: 0.12em;
          color: #61758c;
          margin-bottom: 5px;
        }
        .metric-value {
          font-size: 22px;
          line-height: 1;
          font-weight: 700;
          color: var(--macaw-blue);
          margin-bottom: 4px;
        }
        .metric-note {
          font-size: 11px;
          color: #63707f;
        }
        .btn-primary {
          background-color: var(--macaw-blue);
          border-color: var(--macaw-blue);
        }
        .btn-primary:hover,
        .btn-primary:focus,
        .btn-primary:active {
          background-color: var(--macaw-blue-dark);
          border-color: var(--macaw-blue-dark);
        }
        .btn-submit-app {
          background-color: #2f8f63;
          border-color: #267551;
          color: #ffffff;
          font-weight: 700;
          font-size: 18px;
          padding: 9px 20px;
          line-height: 1.2;
        }
        .btn-submit-app:hover,
        .btn-submit-app:focus,
        .btn-submit-app:active {
          background-color: #267551;
          border-color: #1f5f41;
          color: #ffffff;
        }
        .btn-secondary-action {
          font-size: 18px;
          padding: 9px 20px;
          line-height: 1.2;
        }
        .btn-default {
          border-color: #cfd8e6;
          color: #243b61;
          background-color: #ffffff;
        }
        .btn-danger-app {
          background-color: #b13a3a;
          border-color: #b13a3a;
          color: #ffffff;
        }
        .btn-danger-app:hover,
        .btn-danger-app:focus,
        .btn-danger-app:active {
          background-color: #962f2f;
          border-color: #962f2f;
          color: #ffffff;
        }
        .top-row {
          display: flex;
          flex-wrap: wrap;
          gap: 14px;
          margin-bottom: 0;
          align-items: stretch;
        }
        .left-pane {
          flex: 1 1 58%;
          min-width: 340px;
          display: flex;
        }
        .right-pane {
          flex: 1 1 34%;
          min-width: 320px;
          display: flex;
        }
        .config-card {
          display: flex;
          flex-direction: column;
        }
        .top-row > div > .app-card {
          width: 100%;
          height: 100%;
        }
        .input-actions {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          margin-top: 0;
          align-items: center;
        }
        .input-actions-row {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          align-items: center;
          justify-content: flex-end;
        }
        .input-upload-row {
          display: grid;
          grid-template-columns: minmax(0, 1fr) auto;
          gap: 12px 18px;
          align-items: center;
          margin-top: 12px;
          padding: 12px 14px;
          border: 1px solid rgba(53, 89, 166, 0.12);
          border-radius: 14px;
          background: rgba(255, 255, 255, 0.72);
        }
        .input-upload-file {
          min-width: 0;
        }
        .input-file-status-row {
          display: block;
          align-items: center;
        }
        .input-upload-label {
          font-size: 12px;
          font-weight: 700;
          color: #243b61;
          margin-bottom: 6px;
        }
        .input-file-box {
          flex: 0 1 340px;
          min-width: 260px;
        }
        .input-file-box .shiny-input-container {
          width: 100%;
        }
        .input-file-box .form-group {
          margin-bottom: 0;
        }
        .input-upload-actions {
          display: flex;
          justify-content: flex-end;
          align-items: center;
          min-width: 0;
        }
        .input-status {
          display: inline-flex;
          align-items: center;
          padding: 8px 14px;
          min-height: 42px;
          border-radius: 999px;
          background: rgba(243, 210, 79, 0.18);
          border: 1px solid rgba(53, 89, 166, 0.16);
          color: var(--macaw-blue-dark);
          font-size: 12px;
          line-height: 1;
          white-space: nowrap;
        }
        .config-footer {
          margin-top: auto;
          padding-top: 14px;
          display: flex;
          justify-content: stretch;
          align-items: flex-end;
          border-top: 1px solid rgba(53, 89, 166, 0.12);
        }
        .config-footer .input-status {
          width: 100%;
          background: rgba(103, 170, 231, 0.14);
          border-color: rgba(53, 89, 166, 0.18);
          justify-content: center;
        }
        @media (max-width: 1280px) {
          .input-upload-row {
            grid-template-columns: 1fr;
          }
          .input-upload-actions,
          .input-actions-row {
            justify-content: flex-start;
          }
        }
        .config-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 10px 14px;
        }
        .config-summary {
          margin-top: 16px;
          padding: 14px;
          border: 1px solid rgba(53, 89, 166, 0.12);
          border-radius: 14px;
          background: rgba(255, 255, 255, 0.72);
        }
        .config-summary-title {
          font-size: 12px;
          font-weight: 700;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: #57739a;
          margin-bottom: 10px;
        }
        .config-summary-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 10px;
        }
        .config-summary-card {
          padding: 10px 12px;
          border-radius: 12px;
          background: var(--macaw-cream);
          border: 1px solid rgba(75, 128, 124, 0.14);
        }
        .config-summary-label {
          font-size: 10px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          color: #6e8198;
          margin-bottom: 4px;
        }
        .config-summary-value {
          font-size: 13px;
          color: #243b61;
          line-height: 1.35;
        }
        .half-span {
          grid-column: span 1;
        }
        .full-span {
          grid-column: 1 / -1;
        }
        @media (max-width: 980px) {
          .half-span {
            grid-column: 1 / -1;
          }
          .config-summary-grid {
            grid-template-columns: 1fr;
          }
        }
        .results-toolbar {
          display: flex;
          flex-wrap: wrap;
          justify-content: space-between;
          align-items: flex-start;
          gap: 10px;
          margin-bottom: 10px;
        }
        .toolbar-text {
          flex: 1 1 320px;
        }
        .download-group {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
        }
        .meta-details {
          border: 1px solid rgba(53, 89, 166, 0.14);
          border-radius: 12px;
          background: var(--macaw-cream);
          flex: 1 1 280px;
        }
        .meta-details summary {
          cursor: pointer;
          padding: 10px 12px;
          font-size: 12px;
          font-weight: 600;
          color: var(--macaw-blue);
        }
        .meta-body {
          padding: 0 12px 12px 12px;
        }
        .meta-controls {
          margin-top: 12px;
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          align-items: flex-start;
        }
        .meta-close {
          flex: 0 0 auto;
        }
        .meta-actions {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          align-items: flex-start;
        }
        .summary-row {
          width: 100%;
          margin: 14px 0;
        }
        .small-muted {
          color: #607188;
          font-size: 12px;
        }
      "
      ))
    ),
    shiny::div(
      class = "hero-shell",
      shiny::div(
        class = "hero-layout",
        shiny::div(
          class = "hero-copy",
          shiny::tags$div(
            class = "hero-kicker",
            "Batch Name Resolution For Peru Birds - avesperu"
          ),
          #shiny::tags$h1("avesperu"),
          shiny::tags$p(
            "Application to validate, standardize, and reconcile scientific names for birds of Peru using the UNOP/SACC checklist included in avesperu."
          )
        ),
        shiny::div(
          class = "hero-meta",
          shiny::tags$div(
            class = "hero-meta-card",
            # shiny::tags$div(class = "hero-meta-label", "Contexto"),
            shiny::tags$div(
              class = "hero-meta-line",
              paste("avesperu:", utils::packageVersion("avesperu"))
              #paste("Local checklist:", checklist_date)
            ),
            shiny::tags$div(
              class = "hero-meta-line",
              #paste("avesperu:", utils::packageVersion("avesperu"))
              paste("Local checklist:", checklist_date)
            )
          )
        )
      )
    ),
    shiny::div(
      class = "top-row",
      shiny::div(
        class = "left-pane",
        shiny::div(
          class = "app-card",
          shiny::tags$h3("Input"),
          shiny::tags$p(
            "Enter one name per line or combine pasted text with a CSV, TXT, TSV, or Excel file."
          ),
          shiny::textAreaInput(
            inputId = "names_text",
            label = "Scientific names to check",
            width = "100%",
            height = "300px",
            placeholder = "Falco sparverius\nTinamus osgoodi\nPenelope albipennis"
          ),
          shiny::tags$p(
            class = "small-muted",
            "Enter one scientific name per line. You can also upload a supporting file."
          ),
          shiny::div(
            class = "input-upload-row",
            shiny::div(
              class = "input-upload-file",
              shiny::tags$div(class = "input-upload-label", "Add file"),
              shiny::div(
                class = "input-file-status-row",
                shiny::div(
                  class = "input-file-box",
                  shiny::fileInput(
                    inputId = "upload_names",
                    label = NULL,
                    accept = c(".txt", ".csv", ".tsv", ".xlsx", ".xls")
                  )
                )
              )
            ),
            shiny::div(
              class = "input-upload-actions",
              shiny::div(
                class = "input-actions-row",
                shiny::div(
                  class = "input-actions",
                  shiny::actionButton(
                    "submit_names",
                    "Submit",
                    class = "btn-submit-app btn-sm"
                  ),
                  shiny::actionButton(
                    "clear_all",
                    "Clear",
                    class = "btn-default btn-secondary-action btn-sm"
                  ),
                  shiny::actionButton(
                    "load_sample",
                    "Try sample",
                    class = "btn-default btn-secondary-action btn-sm"
                  )
                )
              )
            )
          )
        ),
      ),
      shiny::div(
        class = "right-pane",
        shiny::div(
          class = "app-card config-card",
          shiny::tags$h3("Configuration"),
          shiny::div(
            class = "config-grid",
            shiny::div(
              class = "full-span",
              shiny::selectInput(
                "processing_mode",
                "Processing Mode",
                choices = c(
                  "Perform Name Resolution" = "resolve",
                  "Parse Names Only" = "parse"
                ),
                selected = "resolve"
              )
            ),
            shiny::div(
              class = "full-span",
              shiny::radioButtons(
                "matching_mode",
                "Matching",
                choices = c(
                  "Fuzzy matching" = "fuzzy",
                  "Exact only" = "exact"
                ),
                selected = "fuzzy",
                inline = TRUE
              )
            ),
            shiny::div(
              class = "half-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve' && input.matching_mode === 'fuzzy'",
                shiny::numericInput(
                  "max_distance",
                  "Max distance",
                  value = 0.1,
                  min = 0,
                  step = 0.01
                )
              )
            ),
            shiny::div(
              class = "half-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve'",
                shiny::numericInput(
                  "batch_size",
                  "Batch size",
                  value = 250,
                  min = 1,
                  step = 50
                )
              )
            ),
            shiny::div(
              class = "half-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve'",
                shiny::numericInput(
                  "n_cores",
                  "Cores (0 = auto)",
                  value = 0,
                  min = 0,
                  step = 1
                )
              )
            ),
            shiny::div(
              class = "full-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve'",
                shiny::checkboxInput(
                  "use_parallel",
                  "Parallel batches",
                  value = FALSE
                )
              )
            )
          ),
          shiny::uiOutput("config_overview"),
          shiny::div(
            class = "config-footer",
            shiny::tags$div(
              class = "input-status",
              shiny::textOutput("input_overview", inline = TRUE)
            )
          )
        )
      ),
    ),
    shiny::tags$details(
      shiny::tags$summary("File import settings and preview"),
      shiny::selectInput(
        "upload_header",
        "Header row",
        c("Recognize standard headers" = "auto", "Yes" = "yes", "No" = "no")
      ),
      shiny::textInput(
        "upload_column",
        "Scientific-name column number (auto if blank)",
        ""
      ),
      shiny::tags$p(
        "Row numbers refer to spreadsheet rows or delimited records, including the header. Empty rows are retained. Maximum 10,000 names and 200 characters per name."
      ),
      DT::DTOutput("upload_preview")
    ),
    shiny::textOutput("processing_status"),
    shiny::div(
      class = "summary-row",
      shiny::uiOutput("summary_cards")
    ),
    shiny::div(
      class = "app-card",
      shiny::tags$h3("Results"),
      shiny::div(
        class = "results-toolbar",
        shiny::div(
          class = "toolbar-text",
          shiny::tags$p(
            "Review every row with review_flag = TRUE, including ambiguous matches and qualifiers. ",
            "The table is filterable and can be exported in CSV, TSV, or XLSX."
          )
        ),
        shiny::div(
          class = "download-group",
          shiny::downloadButton("download_csv", "Download CSV"),
          shiny::downloadButton("download_tsv", "Download TSV"),
          shiny::downloadButton("download_xlsx", "Download XLSX")
        )
      ),
      DT::DTOutput("results_table"),
      shiny::div(
        class = "meta-controls",
        shiny::tags$details(
          class = "meta-details",
          shiny::tags$summary("Run metadata"),
          shiny::tags$div(
            class = "meta-body",
            shiny::tags$p(
              "Summary of settings and source information used for this run."
            ),
            DT::DTOutput("metadata_table")
          )
        ),
        shiny::div(
          class = "meta-close",
          shiny::div(
            class = "meta-actions",
            shiny::downloadButton("download_metadata", "Download settings"),
            shiny::actionButton(
              "stop_app",
              "Close session",
              class = "btn-danger-app"
            )
          )
        )
      )
    )
  )
}

#' @keywords internal
avesperu_app_server <- function(input, output, session) {
  sample_names <- paste(
    c(
      "Falco sparverius",
      "Tinamus osgodi",
      "Penelope albipennis",
      "Crypturellus sooui",
      "Xenoglaux loweryi",
      "Invented bird species"
    ),
    collapse = "\n"
  )

  uploaded_records <- shiny::reactiveVal(pasted_name_records(""))
  upload_error <- shiny::reactiveVal(NULL)
  upload_preview <- shiny::reactiveVal(NULL)
  processed_results <- shiny::reactiveVal(NULL)
  processing_status <- shiny::reactiveVal("Submit a list to begin.")
  active_job <- NULL
  generation <- 0L
  invalidate_results <- function() {
    generation <<- generation + 1L
    stop_app_job(active_job)
    active_job <<- NULL
    processed_results(NULL)
    processing_status("Inputs changed. Submit to process the current list.")
  }
  uploaded_names <- shiny::reactive(uploaded_records()$submitted_name)
  shiny::observeEvent(
    list(input$upload_names, input$upload_header, input$upload_column),
    {
      invalidate_results()
      uploaded_records(pasted_name_records(""))
      upload_error(NULL)
      upload_preview(NULL)
      if (is.null(input$upload_names)) {
        return(invisible(NULL))
      }
      header <- if (is.null(input$upload_header)) {
        "auto"
      } else {
        input$upload_header
      }
      column <- if (
        is.null(input$upload_column) || !nzchar(input$upload_column)
      ) {
        NULL
      } else {
        input$upload_column
      }
      incoming <- tryCatch(
        {
          records <- read_avesperu_name_file(
            input$upload_names$datapath,
            input$upload_names$name,
            header = header,
            column = column,
            records = TRUE
          )
          validate_app_input(records)
          records
        },
        error = function(e) e
      )
      if (inherits(incoming, "error")) {
        upload_error(conditionMessage(incoming))
        upload_preview(incoming$preview)
        shiny::showNotification(conditionMessage(incoming), type = "error")
      } else {
        uploaded_records(incoming)
      }
    },
    ignoreInit = TRUE,
    priority = 20
  )

  shiny::observeEvent(
    list(
      input$names_text,
      input$processing_mode,
      input$matching_mode,
      input$max_distance,
      input$batch_size,
      input$use_parallel,
      input$n_cores
    ),
    {
      invalidate_results()
    },
    ignoreInit = TRUE,
    priority = 10
  )

  shiny::observeEvent(
    input$clear_all,
    {
      invalidate_results()
      uploaded_records(pasted_name_records(""))
      upload_error(NULL)
      upload_preview(NULL)
      shiny::updateTextAreaInput(session, "names_text", value = "")
      session$sendCustomMessage("reset-upload", "upload_names")
    },
    priority = 30
  )

  shiny::observeEvent(input$load_sample, {
    invalidate_results()
    uploaded_records(pasted_name_records(""))
    upload_error(NULL)
    upload_preview(NULL)
    shiny::updateTextAreaInput(session, "names_text", value = sample_names)
    session$sendCustomMessage("reset-upload", "upload_names")
  })

  shiny::observeEvent(input$stop_app, {
    session$close()
  })
  session$onSessionEnded(function() {
    generation <<- generation + 1L
    stop_app_job(active_job)
    active_job <<- NULL
  })

  combined_records <- shiny::reactive({
    rbind(pasted_name_records(input$names_text), uploaded_records())
  })
  combined_names <- shiny::reactive(combined_records()$submitted_name)
  output$upload_preview <- DT::renderDT({
    DT::datatable(
      if (is.null(upload_preview())) {
        utils::head(uploaded_records(), 10)
      } else {
        upload_preview()
      },
      rownames = FALSE,
      options = list(dom = "t", scrollX = TRUE)
    )
  })
  output$processing_status <- shiny::renderText(processing_status())

  output$input_overview <- shiny::renderText({
    pasted_n <- length(split_submitted_names(input$names_text))
    uploaded_n <- length(uploaded_names())
    total_n <- pasted_n + uploaded_n

    paste(
      total_n,
      "name(s) ready |",
      pasted_n,
      "from text |",
      uploaded_n,
      "from file"
    )
  })

  output$config_overview <- shiny::renderUI({
    mode_value <- if (identical(input$processing_mode, "parse")) {
      "Parse names only"
    } else {
      "Resolve names"
    }

    matching_value <- if (!identical(input$processing_mode, "resolve")) {
      "Parsing only"
    } else if (identical(input$matching_mode, "exact")) {
      "Exact only"
    } else {
      paste("Fuzzy up to", format(input$max_distance, trim = TRUE))
    }

    batching_value <- if (!identical(input$processing_mode, "resolve")) {
      "Not used"
    } else {
      paste(format(as.integer(input$batch_size), trim = TRUE), "rows per batch")
    }

    execution_value <- if (!identical(input$processing_mode, "resolve")) {
      "Single pass"
    } else if (isTRUE(input$use_parallel)) {
      core_label <- if (is_count(input$n_cores)) {
        paste(input$n_cores, "cores")
      } else {
        "auto cores"
      }
      paste("Parallel,", core_label)
    } else {
      "Serial execution"
    }

    cards <- list(
      list(label = "Mode", value = mode_value),
      list(label = "Matching", value = matching_value),
      list(label = "Batching", value = batching_value),
      list(label = "Execution", value = execution_value)
    )

    shiny::div(
      class = "config-summary",
      shiny::tags$div(class = "config-summary-title", "Current setup"),
      shiny::div(
        class = "config-summary-grid",
        lapply(cards, function(card) {
          shiny::tags$div(
            class = "config-summary-card",
            shiny::tags$div(class = "config-summary-label", card$label),
            shiny::tags$div(class = "config-summary-value", card$value)
          )
        })
      )
    )
  })

  shiny::observeEvent(
    input$submit_names,
    {
      invalidate_results()
      if (!is.null(upload_error())) {
        processing_status(paste("Fix the uploaded file:", upload_error()))
        return(invisible(NULL))
      }
      records <- combined_records()
      if (!nrow(records)) {
        processing_status("Add at least one scientific name before submitting.")
        return(invisible(NULL))
      }
      settings <- list(
        mode = input$processing_mode,
        max_distance = if (identical(input$matching_mode, "exact")) {
          0
        } else {
          input$max_distance
        },
        batch_size = input$batch_size,
        parallel = isTRUE(input$use_parallel),
        n_cores = if (
          is.null(input$n_cores) ||
            identical(input$n_cores, 0) ||
            identical(input$n_cores, 0L)
        ) {
          NULL
        } else {
          input$n_cores
        }
      )
      error <- tryCatch(
        {
          validate_app_input(records)
          if (!settings$mode %in% c("parse", "resolve")) {
            cli::cli_abort("Select a processing mode.")
          }
          if (settings$mode == "resolve") {
            validate_search_options(
              settings$max_distance,
              TRUE,
              settings$batch_size,
              settings$parallel,
              settings$n_cores
            )
            if (!is.null(settings$n_cores) && settings$n_cores > 4) {
              cli::cli_abort("Use at most four cores in the app.")
            }
          } else {
            settings$max_distance <- NA_real_
            settings$batch_size <- NA_integer_
            settings$parallel <- FALSE
            settings$n_cores <- NULL
          }
          active_job <<- start_app_job(records, settings)
          NULL
        },
        error = function(e) conditionMessage(e)
      )
      if (!is.null(error)) {
        processing_status(error)
        return(invisible(NULL))
      }
      token <- generation
      processing_status(
        "Processing in the background. You can clear or change inputs to cancel."
      )
      poll <- function() {
        if (token != generation || session$isClosed()) {
          return(invisible(NULL))
        }
        if (active_job$is_alive()) {
          later::later(poll, 0.1)
        } else {
          result <- tryCatch(active_job$get_result(), error = function(e) e)
          active_job <<- NULL
          if (inherits(result, "error")) {
            processing_status(conditionMessage(result))
          } else {
            processed_results(result)
            processing_status(
              "Complete. Results and downloads correspond to the current inputs."
            )
          }
        }
      }
      later::later(poll, 0.1)
    },
    ignoreInit = TRUE
  )

  output$summary_cards <- shiny::renderUI({
    state <- processed_results()
    if (is.null(state)) {
      return(
        shiny::div(
          class = "app-card",
          shiny::tags$h3("Summary"),
          shiny::tags$p(
            "Submit a list to see resolution metrics and review cues."
          )
        )
      )
    }

    shiny::div(
      class = "app-card",
      shiny::tags$h3("Summary"),
      metric_cards_ui(summarize_app_results(state$results, mode = state$mode))
    )
  })

  output$results_table <- DT::renderDT({
    state <- processed_results()
    shiny::req(state)

    table_data <- state$results
    dt <- DT::datatable(
      table_data,
      rownames = FALSE,
      filter = "top",
      options = list(
        pageLength = 12,
        lengthMenu = c(12, 25, 50, 100),
        scrollX = TRUE,
        autoWidth = TRUE
      )
    )

    if ("match_type" %in% names(table_data)) {
      dt <- DT::formatStyle(
        dt,
        "match_type",
        target = "row",
        backgroundColor = DT::styleEqual(
          c("exact", "fuzzy", "unmatched"),
          c("#edf7f3", "#fff6d8", "#eef4ff")
        )
      )
      dt <- DT::formatStyle(
        dt,
        "match_type",
        fontWeight = DT::styleEqual(
          c("exact", "fuzzy", "unmatched"),
          c("600", "600", "600")
        ),
        color = DT::styleEqual(
          c("exact", "fuzzy", "unmatched"),
          c("#2f6e68", "#8d6b00", "#3559a6")
        )
      )
    }

    dt
  })

  output$metadata_table <- DT::renderDT({
    state <- processed_results()
    shiny::req(state)

    DT::datatable(
      state$metadata,
      rownames = FALSE,
      options = list(dom = "t", paging = FALSE, ordering = FALSE)
    )
  })

  output$download_csv <- shiny::downloadHandler(
    filename = function() {
      state <- processed_results()
      shiny::req(state)
      paste0("avesperu_", state$mode, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      state <- processed_results()
      shiny::req(state)
      utils::write.csv(state$results, file, row.names = FALSE, na = "")
    }
  )

  output$download_tsv <- shiny::downloadHandler(
    filename = function() {
      state <- processed_results()
      shiny::req(state)
      paste0("avesperu_", state$mode, "_", format(Sys.Date(), "%Y%m%d"), ".tsv")
    },
    content = function(file) {
      state <- processed_results()
      shiny::req(state)
      utils::write.table(
        state$results,
        file = file,
        sep = "\t",
        row.names = FALSE,
        quote = TRUE,
        na = ""
      )
    }
  )

  output$download_xlsx <- shiny::downloadHandler(
    filename = function() {
      state <- processed_results()
      shiny::req(state)
      paste0(
        "avesperu_",
        state$mode,
        "_",
        format(Sys.Date(), "%Y%m%d"),
        ".xlsx"
      )
    },
    content = function(file) {
      state <- processed_results()
      shiny::req(state)
      check_avesperu_xlsx_dep()
      writexl::write_xlsx(
        list(
          results = state$results,
          metadata = state$metadata
        ),
        path = file
      )
    }
  )

  output$download_metadata <- shiny::downloadHandler(
    filename = function() {
      paste0("avesperu_run_metadata_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      state <- processed_results()
      shiny::req(state)
      utils::write.csv(state$metadata, file, row.names = FALSE, na = "")
    }
  )
}
