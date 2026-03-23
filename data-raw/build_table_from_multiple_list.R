library(pdftools)
library(tidyverse)

# Lista de archivos a procesar (puedes añadir los nombres de tus archivos aquí)
archivos <-
 list.files("oldest_data\\listas",
            pattern = "\\.pdf$",
            full.names = TRUE)
archivos
get_aves_tab_universal <- function(pdf_path) {
  text <- pdf_text(pdf_path)

  parse_page <- function(page_text) {
    lines <- page_text |>
      stringr::str_split("\r\n|\n") |>
      unlist() |>
      stringr::str_trim() |>
      tibble(raw = _) |>
      filter(nchar(raw) > 0)

    lines |>
      mutate(
        # Captura de Orden y Familia (en mayúsculas tras la palabra clave)
        order_name = if_else(str_detect(raw, "^Order"), str_extract(raw, "(?<=Order\\s)[A-Z]+"), NA_character_),
        family_name = if_else(str_detect(raw, "^Family"), str_extract(raw, "(?<=Family\\s)[A-Z]+"), NA_character_)
      ) |>
      fill(order_name, family_name, .direction = "down") |>
      # Filtrar encabezados y metadatos del PDF
      filter(!str_detect(raw, "^Order|^Family|SCIENTIFIC NAME|By/por|\\bPage\\b|\\b\\d+\\b|^-$")) |>
      # Extracción del Estatus
      mutate(
        status = str_extract(raw, "\\((E|NB|V|IN|H|EX)\\)"),
        status = str_remove_all(status, "[\\(\\)]"),
        status = if_else(is.na(status), "Residente", status)
      ) |>
      # Limpiar el nombre científico (primera parte de la cadena antes de 2+ espacios)
      mutate(
        scientific_name = str_extract(raw, "^[A-Z][a-z]+\\s[a-z]+(\\s[a-z]+)?"),
        common_parts = str_remove(raw, fixed(scientific_name)) |>
          str_remove("\\((E|NB|V|IN|H|EX)\\)") |>
          str_trim()
      ) |>
      # Separar nombres comunes (Inglés vs Español)
      separate(common_parts, into = c("english_name", "spanish_name"),
               sep = "\\s{2,}", extra = "merge", fill = "right") |>
      filter(!is.na(scientific_name)) |>
      select(order_name, family_name, scientific_name, english_name, spanish_name, status)
  }

  map_dfr(text, parse_page) |>
    mutate(version_source = basename(pdf_path))
}

# Ejemplo de uso para múltiples archivos
todas_las_listas <- map_dfr(archivos, get_aves_tab_universal)
todas_las_listas |>
  distinct(version_source)
todas_las_listas
todas_las_listas |>
  filter(is.na(spanish_name))

lista_aves <- todas_las_listas |>
  filter(!str_detect(scientific_name,
                     "^For |^Para |^According to|^De acuerdo a"))

  lista_aves

  # ── Exportar listas individuales ──────────────────────────────────────────────
  # Directorio de salida = misma carpeta de los PDFs
  dir_salida <- dirname(archivos[1])  # "oldest_data/listas"
  dir_salida
  lista_aves |>
    group_by(version_source) |>
    group_walk(~ {
      # Construir nombre de salida: mismo nombre del PDF pero con .csv
      nombre_xlsx <- file.path(
        dir_salida,
        tools::file_path_sans_ext(.y$version_source) |> paste0(".xlsx")
      )
      writexl::write_xlsx(.x, nombre_xlsx)
      message("Exportado: ", basename(nombre_xlsx), " (", nrow(.x), " filas)")
    })
