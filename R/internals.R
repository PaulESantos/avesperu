#' Standardize Species Names
#'
#'
#' @param splist Character vector of species names
#' @return Standardized species names
#' @keywords internal
standardize_names <- function(splist) {

  # Paso 1
  splist <- trimws(splist)

  # Paso 2: Capitalización
  splist <- vapply(splist, function(x) {
    words <- strsplit(tolower(x), "\\s+")[[1]]
    words[1] <- paste0(toupper(substring(words[1], 1, 1)),
                       substring(words[1], 2))
    if (length(words) > 1) {
      words[2] <- paste0(tolower(substring(words[2], 1, 1)),
                         substring(words[2], 2))
    }
    paste(words, collapse = " ")
  }, character(1), USE.NAMES = FALSE)

  # Paso 3: Limpieza con expreciones regulares combinadas
  # Detectar híbridos primero para warning
  has_hybrid <- grepl("(^x\\s)|( x$)|( x )", splist)

  # Aplicar todas las transformaciones en una sola pasada
  splist <- gsub("\\s*cf\\.\\s*|\\s*aff\\.\\s*", " ", splist)
  splist <- gsub("(^x\\s)|( x$)|( x )", " ", splist)
  splist <- gsub("_", " ", splist)
  splist <- gsub("\\s{2,}", " ", splist)  # Reemplaze multiples espacios con uno
  splist <- trimws(splist)

  # Advertencia sobre híbridos si es necesario
  if (any(has_hybrid)) {
    sp_hybrids <- unique(splist[has_hybrid])
    warning(
      "The 'x' sign indicating hybrids have been removed in ",
      length(sp_hybrids), " name(s) before search.",
      call. = FALSE,
      immediate. = TRUE
    )
  }

  return(splist)
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

# unop_update_date()
# ---------------------------------------------------------------
#' Check if the UNOP Checklist Has Been Updated
#'
#' This function compares the latest update date from the UNOP checklist
#' website with a reference version date. It returns a message indicating
#' whether an update has occurred.
#'
#' @param version_date Character string with the current local version date
#'        (e.g., "05 de abril de 2025").
#'
#' @return A character message indicating if the site has a more recent update.
#' @keywords internal

unop_check_update <- function(version_date = "29 de septiembre de 2025") {
  site_date <- unop_update_date()

  if (is.na(site_date)) {
    return("Could not extract the update date from the website.")
  }

  # Convert both dates to Date format for comparison
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
    return("Unable to parse one or both dates into the proper format.")
  }

  if (fecha_sitio > fecha_version) {
    return(
      paste0(
        "The UNOP database requires an update.\n",
        "A newer version is available (published on ", site_date, ")."
      )
    )
  } else {
    return(
      paste0(
        "The UNOP database is up to date (current version: ", version_date, ")."
      )
    )
  }
}

