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
#' @return The value returned by \code{\link[shiny:runApp]{shiny::runApp}}.
#' @export
#'
#' @examples
#' \dontrun{
#' run_avesperu_app()
#' }
run_avesperu_app <- function(host = "127.0.0.1",
                             port = NULL,
                             launch.browser = interactive()) {
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
  missing_pkgs <- c("shiny", "DT")
  missing_pkgs <- missing_pkgs[!vapply(
    missing_pkgs,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )]

  if (length(missing_pkgs) > 0) {
    cli::cli_abort("To run the Shiny app, install these packages first: {.pkg {missing_pkgs}}", call = parent.frame())
  }
}

#' @keywords internal
check_avesperu_xlsx_dep <- function() {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    cli::cli_abort("To download XLSX files, install the {.pkg writexl} package first.", call = parent.frame())
  }
}

#' @keywords internal
check_avesperu_excel_read_dep <- function() {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort("To upload Excel files, install the {.pkg readxl} package first.", call = parent.frame())
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
read_avesperu_name_file <- function(path, filename = basename(path)) {
  ext <- tolower(tools::file_ext(filename))

  if (ext %in% c("txt", "lst")) {
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    return(split_submitted_names(paste(lines, collapse = "\n")))
  }

  if (ext %in% c("xlsx", "xls")) {
    check_avesperu_excel_read_dep()
    tbl <- as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE)

    if (ncol(tbl) == 0) {
      cli::cli_abort("The uploaded Excel file could not be parsed.", call = parent.frame())
    }

    col_idx <- guess_name_column(tbl)
    return(split_submitted_names(paste(tbl[[col_idx]], collapse = "\n")))
  }

  if (!ext %in% c("csv", "tsv")) {
    cli::cli_abort("Only CSV, TSV, TXT, and Excel uploads are currently supported.", call = parent.frame())
  }

  sep <- if (ext == "tsv") "\t" else ","

  reader <- function(header) {
    utils::read.table(
      path,
      header = header,
      sep = sep,
      quote = "\"",
      comment.char = "",
      stringsAsFactors = FALSE,
      fill = TRUE,
      check.names = FALSE
    )
  }

  tbl <- tryCatch(reader(TRUE), error = function(e) NULL)

  if (is.null(tbl) || ncol(tbl) == 0) {
    tbl <- tryCatch(reader(FALSE), error = function(e) NULL)
  }

  if (is.null(tbl) || ncol(tbl) == 0) {
    cli::cli_abort("The uploaded file could not be parsed.", call = parent.frame())
  }

  col_idx <- guess_name_column(tbl)
  split_submitted_names(paste(tbl[[col_idx]], collapse = "\n"))
}

#' @keywords internal
extract_name_parts <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""

  tokens <- strsplit(trimws(x), "\\s+")

  genus <- vapply(tokens, function(parts) {
    if (length(parts) >= 1 && nzchar(parts[1])) parts[1] else NA_character_
  }, character(1))

  species_epithet <- vapply(tokens, function(parts) {
    if (length(parts) >= 2 && nzchar(parts[2])) parts[2] else NA_character_
  }, character(1))

  infraspecific <- vapply(tokens, function(parts) {
    if (length(parts) >= 3) paste(parts[-c(1, 2)], collapse = " ") else NA_character_
  }, character(1))

  rank_guess <- vapply(tokens, function(parts) {
    if (length(parts) == 0 || !nzchar(parts[1])) {
      "empty"
    } else if (length(parts) == 1) {
      "uninomial"
    } else if (length(parts) == 2) {
      "binomial"
    } else {
      "infraspecific"
    }
  }, character(1))

  data.frame(
    submitted_genus = genus,
    submitted_species_epithet = species_epithet,
    submitted_infraspecific = infraspecific,
    submitted_rank_guess = rank_guess,
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
flag_duplicate_names <- function(x) {
  duplicated(x) | duplicated(x, fromLast = TRUE)
}

#' @keywords internal
build_parse_results <- function(splist) {
  standardized <- standardize_names(splist)
  parts <- extract_name_parts(standardized)

  data.frame(
    input_order = seq_along(splist),
    submitted_name = as.character(splist),
    standardized_name = standardized,
    parts,
    duplicate_input = flag_duplicate_names(standardized),
    review_flag = FALSE,
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
build_resolution_results <- function(splist,
                                     max_distance = 0.1,
                                     batch_size = 250,
                                     parallel = FALSE,
                                     n_cores = NULL) {
  standardized <- standardize_names(splist)
  parts <- extract_name_parts(standardized)

  resolved <- search_avesperu(
    splist = splist,
    max_distance = max_distance,
    return_details = TRUE,
    batch_size = batch_size,
    parallel = parallel,
    n_cores = n_cores
  )

  db <- avesperu::aves_peru_2025_v5
  matched_rows <- db[match(resolved$accepted_name, db$scientific_name), , drop = FALSE]
  edit_distance <- suppressWarnings(as.integer(resolved$dist))

  match_type <- ifelse(
    is.na(resolved$accepted_name),
    "unmatched",
    ifelse(edit_distance == 0L, "exact", "fuzzy")
  )

  data.frame(
    input_order = seq_along(splist),
    submitted_name = as.character(splist),
    standardized_name = standardized,
    parts,
    accepted_name = resolved$accepted_name,
    matched_genus = matched_rows$genus,
    matched_species_epithet = matched_rows$species_epithet,
    order_name = resolved$order_name,
    family_name = resolved$family_name,
    english_name = resolved$english_name,
    spanish_name = resolved$spanish_name,
    status = resolved$status,
    status_code = matched_rows$status_code,
    match_type = match_type,
    edit_distance = edit_distance,
    duplicate_input = flag_duplicate_names(standardized),
    review_flag = match_type != "exact",
    stringsAsFactors = FALSE
  )
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
      label = c("Submitted", "Unique", "Exact", "Fuzzy", "Unmatched"),
      value = c(
        nrow(results),
        length(unique(results$standardized_name)),
        sum(results$match_type == "exact", na.rm = TRUE),
        sum(results$match_type == "fuzzy", na.rm = TRUE),
        sum(results$match_type == "unmatched", na.rm = TRUE)
      ),
      note = c(
        "Rows processed",
        "Unique standardized names",
        "Distance = 0",
        "Review recommended",
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
build_app_metadata <- function(results,
                               mode,
                               max_distance,
                               batch_size,
                               parallel,
                               n_cores,
                               pasted_names,
                               uploaded_names) {
  metrics <- summarize_app_results(results, mode = mode)
  checklist_date <- attr(avesperu::aves_peru_2025_v5, "version_date", exact = TRUE)
  source_url <- "https://sites.google.com/site/boletinunop/checklist"

  data.frame(
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
      if (identical(mode, "resolve")) "Perform Name Resolution" else "Parse Names Only",
      if (identical(mode, "resolve") && isTRUE(max_distance == 0)) "Exact only" else if (identical(mode, "resolve")) "Fuzzy matching" else NA_character_,
      if (identical(mode, "resolve")) as.character(max_distance) else NA_character_,
      if (identical(mode, "resolve")) as.character(batch_size) else NA_character_,
      if (identical(mode, "resolve")) as.character(parallel) else NA_character_,
      if (identical(mode, "resolve")) if (is.null(n_cores)) "auto" else as.character(n_cores) else NA_character_,
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
  checklist_date <- attr(avesperu::aves_peru_2025_v5, "version_date", exact = TRUE)

  shiny::fluidPage(
    title = "avesperu",
    shiny::tags$head(
      shiny::tags$style(shiny::HTML("
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
      "))
    ),
    shiny::div(
      class = "hero-shell",
      shiny::div(
        class = "hero-layout",
        shiny::div(
          class = "hero-copy",
          shiny::tags$div(class = "hero-kicker", "Batch Name Resolution For Peru Birds - avesperu"),
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
          shiny::tags$p("Enter one name per line or combine pasted text with a CSV, TXT, TSV, or Excel file."),
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
                  shiny::actionButton("submit_names", "Submit", class = "btn-submit-app btn-sm"),
                  shiny::actionButton("clear_all", "Clear", class = "btn-default btn-secondary-action btn-sm"),
                  shiny::actionButton("load_sample", "Try sample", class = "btn-default btn-secondary-action btn-sm")
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
                shiny::numericInput("batch_size", "Batch size", value = 250, min = 1, step = 50)
              )
            ),
            shiny::div(
              class = "half-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve'",
                shiny::numericInput("n_cores", "Cores (0 = auto)", value = 0, min = 0, step = 1)
              )
            ),
            shiny::div(
              class = "full-span",
              shiny::conditionalPanel(
                condition = "input.processing_mode === 'resolve'",
                shiny::checkboxInput("use_parallel", "Parallel batches", value = FALSE)
              )
            )
          ),
          shiny::uiOutput("config_overview"),
          shiny::div(
            class = "config-footer",
            shiny::tags$div(class = "input-status", shiny::textOutput("input_overview", inline = TRUE))
          )
        )
      ),
    ),
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
            "Review rows with `match_type = fuzzy` or `unmatched` first. ",
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
            shiny::tags$p("Summary of settings and source information used for this run."),
            DT::DTOutput("metadata_table")
          )
        ),
        shiny::div(
          class = "meta-close",
          shiny::div(
            class = "meta-actions",
            shiny::downloadButton("download_metadata", "Download settings"),
            shiny::actionButton("stop_app", "Close application", class = "btn-danger-app")
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

  uploaded_names <- shiny::reactiveVal(character(0))

  observe_uploaded_file <- shiny::observeEvent(input$upload_names, {
    shiny::req(input$upload_names$datapath)

    names_from_file <- tryCatch(
      read_avesperu_name_file(
        path = input$upload_names$datapath,
        filename = input$upload_names$name
      ),
      error = function(e) e
    )

    if (inherits(names_from_file, "error")) {
      shiny::showNotification(conditionMessage(names_from_file), type = "error")
      return(invisible(NULL))
    }

    uploaded_names(names_from_file)
    shiny::showNotification(
      paste(length(names_from_file), "names loaded from file."),
      type = "message"
    )
  }, ignoreInit = TRUE)

  observe_clear <- shiny::observeEvent(input$clear_all, {
    uploaded_names(character(0))
    shiny::updateTextAreaInput(session, "names_text", value = "")
  })

  observe_sample <- shiny::observeEvent(input$load_sample, {
    shiny::updateTextAreaInput(session, "names_text", value = sample_names)
  })

  observe_stop <- shiny::observeEvent(input$stop_app, {
    shiny::stopApp(invisible(NULL))
  })

  shiny::onStop(function() {
    observe_uploaded_file$destroy()
    observe_clear$destroy()
    observe_sample$destroy()
    observe_stop$destroy()
  })

  combined_names <- shiny::reactive({
    c(split_submitted_names(input$names_text), uploaded_names())
  })

  output$input_overview <- shiny::renderText({
    pasted_n <- length(split_submitted_names(input$names_text))
    uploaded_n <- length(uploaded_names())
    total_n <- pasted_n + uploaded_n

    paste(
      total_n, "name(s) ready |",
      pasted_n, "from text |",
      uploaded_n, "from file"
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
      core_label <- if (!is.null(input$n_cores) && input$n_cores > 0) {
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

  processed_results <- shiny::eventReactive(input$submit_names, {
    current_names <- combined_names()

    if (length(current_names) == 0) {
      shiny::showNotification("Add at least one scientific name before submitting.", type = "warning")
      return(NULL)
    }

    mode <- input$processing_mode
    max_distance <- if (identical(mode, "resolve")) {
      if (identical(input$matching_mode, "exact")) 0 else input$max_distance
    } else {
      NA_real_
    }

    batch_size <- if (identical(mode, "resolve")) as.integer(input$batch_size) else NA_integer_
    use_parallel <- identical(mode, "resolve") && isTRUE(input$use_parallel)
    n_cores <- if (identical(mode, "resolve") && !is.null(input$n_cores) && input$n_cores > 0) {
      as.integer(input$n_cores)
    } else {
      NULL
    }

    results <- shiny::withProgress(message = "Processing names", value = 0.2, {
      if (identical(mode, "resolve")) {
        shiny::incProgress(0.5, detail = "Resolving names against avesperu")
        build_resolution_results(
          splist = current_names,
          max_distance = max_distance,
          batch_size = batch_size,
          parallel = use_parallel,
          n_cores = n_cores
        )
      } else {
        shiny::incProgress(0.5, detail = "Parsing submitted names")
        build_parse_results(current_names)
      }
    })

    list(
      mode = mode,
      results = results,
      metadata = build_app_metadata(
        results = results,
        mode = mode,
        max_distance = max_distance,
        batch_size = batch_size,
        parallel = use_parallel,
        n_cores = n_cores,
        pasted_names = length(split_submitted_names(input$names_text)),
        uploaded_names = length(uploaded_names())
      )
    )
  }, ignoreInit = TRUE)

  output$summary_cards <- shiny::renderUI({
    state <- processed_results()
    if (is.null(state)) {
      return(
        shiny::div(
          class = "app-card",
          shiny::tags$h3("Summary"),
          shiny::tags$p("Submit a list to see resolution metrics and review cues.")
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
      paste0("avesperu_", state$mode, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      state <- processed_results()
      utils::write.csv(state$results, file, row.names = FALSE, na = "")
    }
  )

  output$download_tsv <- shiny::downloadHandler(
    filename = function() {
      state <- processed_results()
      paste0("avesperu_", state$mode, "_", format(Sys.Date(), "%Y%m%d"), ".tsv")
    },
    content = function(file) {
      state <- processed_results()
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
      paste0("avesperu_", state$mode, "_", format(Sys.Date(), "%Y%m%d"), ".xlsx")
    },
    content = function(file) {
      state <- processed_results()
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
      utils::write.csv(state$metadata, file, row.names = FALSE, na = "")
    }
  )
}
