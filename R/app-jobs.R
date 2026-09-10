validate_app_input <- function(records) {
  if (nrow(records) > 10000L) {
    cli::cli_abort("Submit at most 10,000 names per run.")
  }
  if (any(nchar(records$submitted_name) > 200L, na.rm = TRUE)) {
    cli::cli_abort("Names must contain at most 200 characters.")
  }
  invisible(records)
}

start_app_job <- function(records, settings) {
  validate_app_input(records)
  package_path <- getNamespaceInfo(asNamespace("avesperu"), "path")
  callr::r_bg(
    function(package_path, records, settings) {
      options(avesperu.check_updates = FALSE)
      if (file.exists(file.path(package_path, "R", "get_avesperu.R"))) {
        pkgload::load_all(package_path, helpers = FALSE, quiet = TRUE)
      } else {
        library(
          "avesperu",
          lib.loc = dirname(package_path),
          character.only = TRUE
        )
      }
      ns <- asNamespace("avesperu")
      results <- if (settings$mode == "resolve") {
        get("build_resolution_results", ns)(
          records$submitted_name,
          settings$max_distance,
          settings$batch_size,
          settings$parallel,
          settings$n_cores
        )
      } else {
        get("build_parse_results", ns)(records$submitted_name)
      }
      results$source_file <- records$source_file
      results$source_row <- records$source_row
      metadata <- get("build_app_metadata", ns)(
        results,
        settings$mode,
        settings$max_distance,
        settings$batch_size,
        settings$parallel,
        settings$n_cores,
        sum(records$source_file == "pasted text"),
        sum(records$source_file != "pasted text")
      )
      list(mode = settings$mode, results = results, metadata = metadata)
    },
    args = list(
      package_path = package_path,
      records = records,
      settings = settings
    ),
    supervise = TRUE
  )
}

stop_app_job <- function(job) {
  if (!is.null(job) && job$is_alive()) {
    job$kill_tree()
  }
  invisible(NULL)
}

pasted_name_records <- function(text) {
  if (is.null(text) || is.na(text) || !nzchar(text)) {
    return(data.frame(
      stringsAsFactors = FALSE,
      submitted_name = character(),
      source_file = character(),
      source_row = integer()
    ))
  }
  names <- trimws(strsplit(text, "\r\n|\r|\n")[[1]])
  rows <- which(nzchar(names))
  data.frame(
    stringsAsFactors = FALSE,
    submitted_name = names[rows],
    source_file = rep("pasted text", length(rows)),
    source_row = rows
  )
}
