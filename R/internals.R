# Function to clean species list names
#' @keywords internal
standardize_names <- function(splist) {
  fixed1 <- simple_cap(trimws(splist)) # all up
  fixed2 <- gsub("cf\\.", "", fixed1)
  fixed3 <- gsub("aff\\.", "", fixed2)
  fixed4 <- trimws(fixed3) # remove trailing and leading space
  fixed5 <- gsub("_", " ", fixed4) # change names separated by _ to space

  # Hybrids
  fixed6 <- gsub("(^x )|( x$)|( x )", " ", fixed5)
  hybrids <- fixed5 == fixed6
  if (!all(hybrids)) {
    sp_hybrids <- splist[!hybrids]
    warning(paste("The 'x' sign indicating hybrids have been removed in the",
                  "following names before search:",
                  paste(paste0("'", sp_hybrids, "'"), collapse = ", ")),
            immediate. = TRUE, call. = FALSE)
  }
  # Merge multiple spaces
  fixed7 <- gsub("(?<=[\\s])\\s*|^\\s+|\\s+$", "", fixed6, perl = TRUE)
  return(fixed7)
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
#'
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
    return("Could not convert one or both dates into proper format.")
  }

  if (fecha_sitio > fecha_version) {
    return(paste0("UNOP database has been updated! New version: ", site_date))
  } else {
    return(paste0("UNOP database is up to date (", site_date, ")."))
  }
}


