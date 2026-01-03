## code to prepare `build_table` dataset goes here
library(pdftools)
library(tidyverse)

text <- pdf_text("List of the Birds of Peru 2025 04_1.pdf" )

length(text)

get_aves_tab <- function(text){
  text_ <- text |>
    stringr::str_split("\r|\n") |>
    unlist()

  text_ |>
    tibble::enframe() |>
    dplyr::mutate(value = stringr::str_trim(value)) |>  # Elimina espacios en blanco al inicio y al final
    dplyr::filter(nchar(value) > 0) |>
    tidyr::separate(value,
             into = c("scientific_name", "english_name", "spanish_name"), # Cambiado el orden de columnas
             sep = "\\s{2,}",            # Divide por al menos dos espacios consecutivos
             extra = "merge",            # Une valores adicionales si hay más de 3 columnas
             fill = "right",
             remove = FALSE)    |>
    dplyr::select(-c(1:2)) |>
    dplyr::mutate(family_name =
                    dplyr::if_else(
                    stringr::str_detect(scientific_name, "F[a-z]{1,} [A-Z]{1,}"),
               scientific_name,
               NA_character_
             )) |>
    dplyr::mutate(order_name =
                    dplyr::if_else(
               stringr::str_detect(scientific_name, "O[a-z]{1,} [A-Z]{1,}"),
               scientific_name,
               NA_character_
             )) |>
    dplyr::mutate(status = dplyr::case_when(
      stringr::str_detect(scientific_name, "\\(.*?\\)")~
        stringr::str_extract(scientific_name,
                    "(?<=\\().*?(?=\\))"),
      TRUE ~ "X"
    )
    ) |>
    tidyr::fill(family_name, .direction = "down") |>
    tidyr::fill(order_name, .direction = "down") |>
    dplyr::relocate(order_name, family_name, dplyr::everything()) |>
    dplyr::filter(#!is.na(family_name),
           !is.na(spanish_name)) |>
    dplyr::mutate(
      order_name = stringr::str_extract(order_name, "\\b[A-Z]+\\b") |>
        stringr::str_to_sentence(),
      family_name = stringr::str_extract(family_name, "\\b[A-Z]+\\b") |>
        stringr::str_to_sentence()
    ) |>
    #  select(scientific_name, categoria) |>
    dplyr::mutate(scientific_name = dplyr::case_when(
      stringr::str_detect(scientific_name, "\\(.*?\\)") ~
        stringr::str_remove(scientific_name, "\\(.*?\\)") |>
        stringr::str_trim() |>
        stringr::str_squish(),
      TRUE ~ scientific_name
    ))

}

aves_peru_2025_4 <- purrr::map_dfr(text[1:33],
                            ~ get_aves_tab(.))

aves_peru_2025_v4 <- aves_peru_2025_4 |>
  tidyr::fill(family_name, .direction = "down") |>
  tidyr::fill(order_name, .direction = "down") |>
  dplyr::filter(!is.na(order_name),
         !is.na(family_name))


aves_peru_2025_v4


aves_peru_2025_v4 |>
  dplyr::count(status) |>
  janitor::adorn_totals()


#' (E) = endémico; una especie es considerada endémica para Perú hasta que un registro fuera de sus fronteras ha sido publicado.
#' (NB) = especies que ocurren regularmente en Perú, pero solo en su período no reproductivo.
#' (V) = especies [errante] que ocurren ocasionalmente en Perú y no son parte de la avifauna habitual.
#' (IN) = especies introducidas en Perú por humanos (o se han establecido (colonizado) de poblaciones introducidas en otro lugar) y han
#' establecido.poblaciones reproductivas auto suficientes.
#' (H) = hipotéticos (registros basados solamente en observaciones, especímenes de dudosa procedencia, fotografías no publicadas o grabaciones
#'                    mantenidas en manos privadas).
#' (EX) = especies extintas o que han sido extirpadas de Perú.

categoria_map <- c(
  "X" = "residente", #
  "E" = "endémico",
  "NB" = "migratorio",
  "V" = "divagante",
  "IN" = "introducido",
  "EX" = "extirpado",
  "H" = "hipotético"
)
length(categoria_map)

aves_peru_2025_v4 <- aves_peru_2025_v4 |>
  dplyr::mutate(status = dplyr::recode(status, !!!categoria_map)) |>
  dplyr::mutate(status = stringr::str_to_sentence(status))

aves_peru_2025_v4 |>
  dplyr::count(status) |>
  janitor::adorn_totals()

# 2024 v2
#1#  X = residente:      1542 v
#2#  E = endémico:       117  v
#3#  NB = migratorio:    138  v
#4#  V = divagante:      83   v
#5#  IN = introducido:   3    v
#6#  EX = extirpado:     0    v
#7#  H = hipotético:     26   v
################################
# 2025 v1
# X = residente:      1542
# E = endémico:       118
# NB = migratorio:    138
# V = divagante:      84
# IN = introducido:   3
# EX = extirpado:     0
# H = hipotético:     26
#################################
# 2025 - v2
# X = residente:      1542
# E = endémico:       119
# NB = migratorio:    138
# V = divagante:      84
# IN = introducido:   3
# EX = extirpado:     0
# H = hipotético:     26

#################################
# 2025 - v3
# Divagante   85
# Endémico  119
# Hipotético   23
# Introducido    3
# Migratorio  139
# Residente 1545
# Total 1914

####################################
# 2025 - v4
# X = residente:      1547 *
# E = endémico:       120 revisar
# NB = migratorio:    139 *
# V = divagante:      85 *
# IN = introducido:   3 *
# EX = extirpado:     0
# H = hipotético:     23 *
# Total: 1917


usethis::use_data(aves_peru_2025_v4,
                  compress = "xz",
                  overwrite = TRUE)

# Data for septiembre 2025 imported from Excel file
df <- readxl::read_excel("org_data\\Lista de las aves del Peru 04 oct 2025.xlsx") |>
  dplyr::select(-c(3,4)) |>
  purrr::set_names(c("order_name",
                     "family_name",
                     "scientific_name",
                     "spanish_name",
                     "english_name",
                     "status_code",
                     "status"
                     ))
df
df |>
  dplyr::distinct(order_name) |>
  purrr::flatten_chr()
# X = residente:      1547
# E = endémico:        120
# NB = migratorio:     139
# V = divagante:        85
# IN = introducido:      3
# EX = extirpado:        0
# Subtotal:           1894
# H = hipotético:       23
df |>
  dplyr::count(status, status_code) |>
  janitor::adorn_totals()

categoria_map <- c(
  "X" = "residente", #
  "E" = "endémico",
  "NB" = "migratorio",
  "V" = "divagante",
  "IN" = "introducido",
  "EX" = "extirpado",
  "H" = "hipotético",
  "U" = "hipotético",
  "P" = "divagante"
)

length(categoria_map)

aves_peru_2025_v4 <- df |>
  dplyr::mutate(status = dplyr::recode(status, !!!categoria_map)) |>
  dplyr::mutate(status = stringr::str_to_sentence(status)) |>
  dplyr::mutate(status = ifelse(status == "Divagante!", "Divagante", status))

aves_peru_2025_v4

aves_peru_2025_v4 |>
  dplyr::count(status) |>
  janitor::adorn_totals()

aves_peru_2025_v4 |>
  collapse::fgroup_by(status) |>
  collapse::fsummarise(n = dplyr::n_distinct(scientific_name)) |>
  janitor::adorn_totals()

aves_peru_2025_v4 <-
  aves_peru_2025_v4 |>
  dplyr::select(-status_code)
aves_peru_2025_v4


usethis::use_data(aves_peru_2025_v4,
                  compress = "xz",
                  overwrite = TRUE)


aves_peru_2025_v4 |>
  writexl::write_xlsx("org_data\\bird_of_peru_unop_v4_2025_19112025.xlsx")
