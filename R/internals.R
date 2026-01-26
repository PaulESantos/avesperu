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
    warning(
      "The 'x' sign indicating hybrids have been removed in ",
      length(unique(x[has_hybrid])), " name(s) before search.",
      call. = FALSE,
      immediate. = TRUE
    )
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
  # URL del sitio web
  url_unop <- "https://sites.google.com/site/boletinunop/checklist"

  # Leer HTML
  page <- xml2::read_html(url_unop)
  raw_text <- xml2::xml_text(page)

  # Limpieza de texto
  clean_text <- gsub("\\s+", " ", raw_text)
  clean_text <- gsub("([a-zA-Z])\\.([A-Z])", "\\1. \\2", clean_text)
  clean_text <- trimws(clean_text)

  # Separar por frases
  text_lines <- unlist(strsplit(clean_text, "(?<=\\.)\\s+", perl = TRUE))

  # Buscar linea que contenga "Actualizado"
  date_line <- grep("Actualizado", text_lines, value = TRUE)

  # Buscar fecha con expresion regular
  match <- regexpr("[0-9]{2} de [a-z]+ de [0-9]{4}", date_line)

  if (match[1] != -1) {
    fecha <- substr(date_line, match[1], match[1] + attr(match, "match.length") - 1)
  } else {
    fecha <- NA
  }

  return(fecha)
}

#unop_update_date()
# ---------------------------------------------------------------
#' Check if the UNOP Checklist Has Been Updated
#'
#' This function compares the latest update date from the UNOP checklist
#' website with a reference version date. It returns a message indicating
#' whether an update has occurred.
#'
#'
#' @return A character message indicating if the site has a more recent update.
#' @keywords internal

unop_check_update <- function() {
  site_date <- unop_update_date()
  version_date <- attr(avesperu::aves_peru_2025_v5, "version_date")

  if (is.na(site_date)) {
    cli::cli_alert_danger(
      "Failed to retrieve the update date from the website."
    )
    return(invisible(NULL))
  }

  parse_fecha <- function(fecha_str) {
    meses <- c("enero", "febrero", "marzo", "abril", "mayo", "junio",
               "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
    for (i in seq_along(meses)) {
      fecha_str <- gsub(meses[i], sprintf("%02d", i), fecha_str)
    }
    as.Date(fecha_str, format = "%d de %m de %Y")
  }

  fecha_sitio <- parse_fecha(site_date)
  fecha_version <- parse_fecha(version_date)

  if (is.na(fecha_sitio) || is.na(fecha_version)) {
    cli::cli_alert_warning(
      "Unable to parse one or both dates in the expected format."
    )
    return(invisible(NULL))
  }

  if (fecha_sitio > fecha_version) {
    cli::cli_alert_warning(
      "A newer UNOP checklist version is available."
    )
    cli::cli_alert_info(
      "Latest online version date: {site_date}."
    )
  } else {
    cli::cli_alert_success(
      "The UNOP checklist is up to date (current version: {version_date})."
    )
  }

  invisible(NULL)
}
