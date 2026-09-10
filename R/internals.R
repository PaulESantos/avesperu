normalize_name_records <- function(splist, warn = TRUE) {
  original <- as.character(splist)
  clean <- gsub("_", " ", original, fixed = TRUE)
  tokens <- strsplit(trimws(clean), "[[:space:]\\x{00a0}]+", perl = TRUE)
  hybrid <- vapply(
    tokens,
    function(x) any(tolower(x) %in% c("x", "\u00d7")),
    logical(1)
  )
  qualifier <- vapply(
    tokens,
    function(x) any(tolower(x) %in% c("cf.", "aff.")),
    logical(1)
  )
  standardized <- vapply(
    tokens,
    function(x) {
      if (length(x) == 1L && is.na(x)) {
        return(NA_character_)
      }
      x <- tolower(x)
      x <- x[!x %in% c("x", "\u00d7", "cf.", "aff.")]
      text <- paste(x, collapse = " ")
      paste0(toupper(substr(text, 1, 1)), substring(text, 2))
    },
    character(1),
    USE.NAMES = FALSE
  )
  if (warn && any(hybrid)) {
    count <- length(unique(standardized[hybrid]))
    cli::cli_warn(
      "The 'x' sign indicating hybrids have been removed in {count} name{?s} before search. Review is required."
    )
  }
  data.frame(
    submitted_name = original,
    standardized_name = standardized,
    has_qualifier = qualifier,
    has_hybrid = hybrid,
    stringsAsFactors = FALSE
  )
}

standardize_names <- function(splist) {
  normalize_name_records(splist)$standardized_name
}

#' @keywords internal
simple_cap <- function(x) {
  # Split each string into words, remove unnecessary white spaces, and convert to lowercase
  words <- sapply(strsplit(x, "\\s+"), function(words) {
    paste(tolower(words), collapse = " ")
  })

  # Capitalize the first letter of each word
  capitalized <- sapply(strsplit(words, ""), function(word) {
    if (length(word) > 0) {
      word[1] <- toupper(word[1])
    }
    paste(word, collapse = "")
  })

  return(capitalized)
}

#' @keywords internal
find_duplicates <- function(vector) {
  # Count the frequency of each word
  word_counts <- table(vector)
  # Find words with a frequency greater than 1
  duplicated_words <- names(word_counts[word_counts > 1])
  return(duplicated_words)
}

# ---------------------------------------------------------------
#' Get Last Update Date from UNOP Checklist Website
#'
#' This function scrapes the "Boletin UNOP" checklist page and extracts
#' the last update date mentioned in the text.
#'
#' @return A character string with the date in the format "dd de mes de yyyy",
#'         or NA if no date is found.
#' @keywords internal
#' @noRd
unop_update_date <- function() {
  url_unop <- "https://sites.google.com/site/boletinunop/checklist"

  if (!requireNamespace("xml2", quietly = TRUE)) {
    out <- NA_character_
    attr(
      out,
      "reason"
    ) <- "Package 'xml2' is required to check the UNOP website."
    attr(out, "source_url") <- url_unop
    return(out)
  }

  page <- tryCatch(
    xml2::read_html(url_unop),
    error = function(e) e
  )

  if (inherits(page, "error")) {
    out <- NA_character_
    attr(out, "reason") <- conditionMessage(page)
    attr(out, "source_url") <- url_unop
    return(out)
  }

  fecha <- extract_unop_update_date(xml2::xml_text(page))
  attr(fecha, "source_url") <- url_unop

  fecha
}

extract_unop_update_date <- function(text) {
  text <- tolower(gsub("[[:space:]\\x{00a0}]+", " ", text, perl = TRUE))
  pattern <- "actualizad[oa][^0-9]{0,80}[0-9]{1,2} de [a-z]+ de [0-9]{4}"
  hits <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1]]
  dates <- sub(
    "^.*?([0-9]{1,2} de [a-z]+ de [0-9]{4})$",
    "\\1",
    hits,
    perl = TRUE
  )
  parsed <- as.Date(vapply(
    dates,
    function(x) as.character(parse_unop_date(x)),
    character(1)
  ))
  if (!length(parsed) || all(is.na(parsed))) {
    out <- NA_character_
    attr(
      out,
      "reason"
    ) <- "Could not parse an update date associated with 'Actualizado' on the UNOP website."
    return(out)
  }
  dates[which.max(parsed)]
}

#' Parse a UNOP checklist date
#'
#' @param fecha_str A character string in the format "dd de mes de yyyy".
#'
#' @return A Date vector of length 1, or `NA` if parsing fails.
#' @keywords internal
#' @noRd
parse_unop_date <- function(fecha_str) {
  if (length(fecha_str) != 1 || is.na(fecha_str) || !nzchar(fecha_str)) {
    return(as.Date(NA))
  }

  meses <- c(
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre"
  )

  fecha_str <- tolower(trimws(fecha_str))
  fecha_str <- sub("setiembre", "septiembre", fecha_str, fixed = TRUE)
  if (!grepl("^[0-9]{1,2} de [a-z]+ de [0-9]{4}$", fecha_str)) {
    return(as.Date(NA))
  }

  for (i in seq_along(meses)) {
    fecha_str <- gsub(meses[i], sprintf("%02d", i), fecha_str, fixed = TRUE)
  }

  as.Date(fecha_str, format = "%d de %m de %Y")
}

# ---------------------------------------------------------------
#' Check whether the local dataset is up to date against UNOP
#'
#' This function compares the local dataset version date stored in
#' `aves_peru_2026_v1` against the latest update date published on the
#' UNOP checklist website. It is designed to be called explicitly by the
#' user, or enabled through the `avesperu.check_updates` option.
#'
#' @param verbose Logical. If `TRUE`, prints a summary with `cli` alerts.
#'   If `FALSE`, returns the result silently. Default: `interactive()`.
#'
#' @return An invisible named list with the fields `success`, `is_up_to_date`,
#'   `has_update`, `current_version_date`, `online_version_date`, `checked_at`,
#'   `source_url`, and `message`.
#' @export
unop_check_update <- function(verbose = interactive()) {
  if (!is.logical(verbose) || length(verbose) != 1 || is.na(verbose)) {
    cli::cli_abort(
      "{.arg verbose} must be a single TRUE or FALSE value.",
      call = parent.frame()
    )
  }

  source_url <- "https://sites.google.com/site/boletinunop/checklist"
  site_date <- unop_update_date()
  version_date <- attr(current_checklist(), "version_date")
  result <- list(
    success = FALSE,
    is_up_to_date = NA,
    has_update = NA,
    current_version_date = version_date,
    online_version_date = unname(site_date),
    checked_at = Sys.time(),
    source_url = source_url,
    message = NULL
  )

  failure_reason <- attr(site_date, "reason", exact = TRUE)

  if (is.na(site_date)) {
    result$message <- if (!is.null(failure_reason)) {
      paste("Could not check the UNOP website:", failure_reason)
    } else {
      "Could not retrieve the update date from the UNOP website."
    }

    if (verbose) {
      cli::cli_alert_warning(result$message)
    }

    return(invisible(result))
  }

  fecha_sitio <- parse_unop_date(site_date)
  fecha_version <- parse_unop_date(version_date)

  if (is.na(fecha_sitio) || is.na(fecha_version)) {
    result$message <- paste(
      "Could not parse one or both dates.",
      "Local version date:",
      version_date,
      "| Online version date:",
      site_date
    )

    if (verbose) {
      cli::cli_alert_warning(result$message)
    }

    return(invisible(result))
  }

  result$success <- TRUE
  result$has_update <- fecha_sitio > fecha_version
  result$is_up_to_date <- !result$has_update

  if (result$has_update) {
    result$message <- paste(
      "A newer UNOP checklist version is available.",
      "Local dataset date:",
      version_date,
      "| Online checklist date:",
      site_date
    )

    if (verbose) {
      cli::cli_alert_warning("A newer UNOP checklist version is available.")
      cli::cli_alert_info("Local dataset date: {version_date}.")
      cli::cli_alert_info("Latest online checklist date: {site_date}.")
    }
  } else {
    result$message <- paste(
      "The local avesperu dataset is up to date.",
      "Local dataset date:",
      version_date,
      "| Online checklist date:",
      site_date
    )

    if (verbose) {
      cli::cli_alert_success("The local avesperu dataset is up to date.")
      cli::cli_alert_info("Local dataset date: {version_date}.")
      cli::cli_alert_info("Latest online checklist date: {site_date}.")
    }
  }

  invisible(result)
}
