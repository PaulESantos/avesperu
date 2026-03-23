#' Standardize Species Names
#'
#' @param splist Character vector of species names
#' @return Standardized species names
#' @keywords internal
standardize_names <- function(splist) {

  # Forzar a character pero preservando NA
  splist <- as.character(splist)

  # Guardar NA y trabajar solo con no-NA
  na_idx <- is.na(splist)
  out <- splist

  if (all(na_idx)) return(out)

  x <- splist[!na_idx]

  # Paso 1: trim
  x <- trimws(x)

  # Paso 2: detectar y remover hibridos ANTES de capitalizar (x/× como token aislado)
  hybrid_pat <- "(^|\\s)[x\\u00D7](\\s|$)"
  has_hybrid <- grepl(hybrid_pat, x, ignore.case = TRUE)

  # Remover y normalizar espacios inmediatamente
  x <- gsub(hybrid_pat, " ", x, ignore.case = TRUE)
  x <- gsub("\\s{2,}", " ", x)
  x <- trimws(x)

  # Paso 3: limpieza general
  x <- gsub("\\s*cf\\.\\s*|\\s*aff\\.\\s*", " ", x)
  x <- gsub("_", " ", x)
  x <- gsub("\\s{2,}", " ", x)
  x <- trimws(x)

  # Warning (solo sobre no-NA)
  if (any(has_hybrid, na.rm = TRUE)) {
    cli::cli_warn(c(
      "!" = "The 'x' sign indicating hybrids have been removed in {length(unique(x[has_hybrid]))} name{?s} before search."
    ), call = parent.frame())
  }

  # Paso 4: capitalizacion
  x <- vapply(x, function(s) {
    words <- strsplit(tolower(s), "\\s+")[[1]]

    if (length(words) >= 1) {
      words[1] <- paste0(
        toupper(substring(words[1], 1, 1)),
        substring(words[1], 2)
      )
    }
    if (length(words) >= 2) {
      words[2] <- tolower(words[2])
    }

    paste(words, collapse = " ")
  }, character(1), USE.NAMES = FALSE)

  # Reinsertar
  out[!na_idx] <- x
  out
}

#' @keywords internal
simple_cap <- function(x) {
  # Split each string into words, remove unnecessary white spaces, and convert to lowercase
  words <- sapply(strsplit(x, "\\s+"), function(words) paste(tolower(words), collapse = " "))

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
unop_update_date <- function() {
  url_unop <- "https://sites.google.com/site/boletinunop/checklist"

  if (!requireNamespace("xml2", quietly = TRUE)) {
    out <- NA_character_
    attr(out, "reason") <- "Package 'xml2' is required to check the UNOP website."
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

  raw_text <- xml2::xml_text(page)
  clean_text <- gsub("\\s+", " ", raw_text)
  clean_text <- gsub("([a-zA-Z])\\.([A-Z])", "\\1. \\2", clean_text)
  clean_text <- trimws(clean_text)

  text_lines <- unlist(strsplit(clean_text, "(?<=\\.)\\s+", perl = TRUE))
  date_line <- grep("Actualizado", text_lines, value = TRUE)

  if (length(date_line) == 0) {
    out <- NA_character_
    attr(out, "reason") <- "Could not find the 'Actualizado' line on the UNOP website."
    attr(out, "source_url") <- url_unop
    return(out)
  }

  match <- regexpr("[0-9]{2} de [a-z]+ de [0-9]{4}", date_line[1])

  if (match[1] != -1) {
    fecha <- substr(date_line[1], match[1], match[1] + attr(match, "match.length") - 1)
    attr(fecha, "source_url") <- url_unop
  } else {
    fecha <- NA_character_
    attr(fecha, "reason") <- "Could not parse the update date from the UNOP website."
    attr(fecha, "source_url") <- url_unop
  }

  fecha
}

#' Parse a UNOP checklist date
#'
#' @param fecha_str A character string in the format "dd de mes de yyyy".
#'
#' @return A Date vector of length 1, or `NA` if parsing fails.
#' @keywords internal
parse_unop_date <- function(fecha_str) {
  if (length(fecha_str) != 1 || is.na(fecha_str) || !nzchar(fecha_str)) {
    return(as.Date(NA))
  }

  meses <- c("enero", "febrero", "marzo", "abril", "mayo", "junio",
             "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")

  fecha_str <- tolower(trimws(fecha_str))

  for (i in seq_along(meses)) {
    fecha_str <- gsub(meses[i], sprintf("%02d", i), fecha_str, fixed = TRUE)
  }

  as.Date(fecha_str, format = "%d de %m de %Y")
}

# ---------------------------------------------------------------
#' Check whether the local dataset is up to date against UNOP
#'
#' This function compares the local dataset version date stored in
#' `aves_peru_2025_v5` against the latest update date published on the
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
    cli::cli_abort("{.arg verbose} must be a single TRUE or FALSE value.", call = parent.frame())
  }

  source_url <- "https://sites.google.com/site/boletinunop/checklist"
  site_date <- unop_update_date()
  version_date <- attr(avesperu::aves_peru_2025_v5, "version_date")
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
      "Local version date:", version_date,
      "| Online version date:", site_date
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
      "Local dataset date:", version_date,
      "| Online checklist date:", site_date
    )

    if (verbose) {
      cli::cli_alert_warning("A newer UNOP checklist version is available.")
      cli::cli_alert_info("Local dataset date: {version_date}.")
      cli::cli_alert_info("Latest online checklist date: {site_date}.")
    }
  } else {
    result$message <- paste(
      "The local avesperu dataset is up to date.",
      "Local dataset date:", version_date,
      "| Online checklist date:", site_date
    )

    if (verbose) {
      cli::cli_alert_success("The local avesperu dataset is up to date.")
      cli::cli_alert_info("Local dataset date: {version_date}.")
      cli::cli_alert_info("Latest online checklist date: {site_date}.")
    }
  }

  invisible(result)
}
