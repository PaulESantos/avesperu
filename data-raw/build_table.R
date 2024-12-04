## code to prepare `build_table` dataset goes here
library(pdftools)
library(tidyverse)

text <- pdf_text("List of the Birds of Peru 2024 03.pdf" )

get_aves_tab <- function(text){
  text_ <- text |>
    str_split("\r|\n") |>
    unlist()

  text_ |>
    enframe() |>
    mutate(value = str_trim(value)) |>  # Elimina espacios en blanco al inicio y al final
    filter(nchar(value) > 0) |>
    separate(value,
             into = c("scientific_name", "english_name", "spanish_name"), # Cambiado el orden de columnas
             sep = "\\s{2,}",            # Divide por al menos dos espacios consecutivos
             extra = "merge",            # Une valores adicionales si hay más de 3 columnas
             fill = "right",
             remove = FALSE)    |>
    select(-c(1:2)) |>
    mutate(family_name =
             if_else(
               str_detect(scientific_name, "F[a-z]{1,} [A-Z]{1,}"),
               scientific_name,
               NA_character_
             )) |>
    mutate(order_name =
             if_else(
               str_detect(scientific_name, "O[a-z]{1,} [A-Z]{1,}"),
               scientific_name,
               NA_character_
             )) |>
    mutate(status = case_when(
      str_detect(scientific_name, "\\(.*?\\)")~
        str_extract(scientific_name,
                    "(?<=\\().*?(?=\\))"),
      TRUE ~ "X"
    )
    ) |>
    fill(family_name, .direction = "down") |>
    fill(order_name, .direction = "down") |>
    relocate(order_name, family_name, everything()) |>
    filter(#!is.na(family_name),
           !is.na(spanish_name)) |>
    mutate(
      order_name = str_extract(order_name, "\\b[A-Z]+\\b") |>
        str_to_sentence(),
      family_name = str_extract(family_name, "\\b[A-Z]+\\b") |>
        str_to_sentence()
    ) |>
    #  select(scientific_name, categoria) |>
    mutate(scientific_name = case_when(
      str_detect(scientific_name, "\\(.*?\\)") ~
        str_remove(scientific_name, "\\(.*?\\)") |>  str_trim() |>  str_squish(),
      TRUE ~ scientific_name
    ))

}

aves_peru_2024_2 <- map_dfr(text[1:34],
                            ~ get_aves_tab(.))

aves_peru_2024_v2 <- aves_peru_2024_2 |>
  fill(family_name, .direction = "down") |>
  fill(order_name, .direction = "down") |>
  filter(!is.na(order_name),
         !is.na(family_name))

aves_peru_2024_v2

categoria_map <- c(
  "X" = "residente",
  "E" = "endémico",
  "NB" = "migratorio",
  "V" = "divagante",
  "IN" = "introducido",
  "EX" = "extirpado",
  "H" = "hipotético"
)

aves_peru_2024_v2 <- aves_peru_2024_v2 |>
  mutate(status = recode(status, !!!categoria_map)) |>
  mutate(status = str_to_sentence(status))
aves_peru_2024_v2
aves_peru_2024_v2 |>
  count(status)
#1#  X = residente:      1542 v
#2#  E = endémico:       117  v
#3#  NB = migratorio:    138  v
#4#  V = divagante:      83   v
#5#  IN = introducido:   3    v
#6#  EX = extirpado:     0    v
#7#  H = hipotético:     26   v


usethis::use_data(aves_peru_2024_v2,
                  compress = "xz",
                  overwrite = TRUE)
