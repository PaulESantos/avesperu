# geta data ---------------------------------------------------------------

library(tidyverse)
library(tabulizer)
library(pdftools)
files <- list.files(pattern = "pdf$")
files
pdf <- tabulizer::extract_text("List of the Birds of Peru 2023 01.pdf",
                                 encoding = "UTF-8",
                               page = 1)
pdf |>
  str_split("\n")
length(pdf)

pdf[[1]]


pdf1 <- pdftools::pdf_text("List of the Birds of Peru 2023 01.pdf"
                           )

pdf_1 <- pdf1 |>
  str_split("\n") |>
  unlist()
pdf_1[-c(1:11)] |>  head()

text_tbl <- tibble::tibble(text = pdf_1)
bird_of_peru_list <- text_tbl |>
  filter(nchar(text)> 1) |>
  mutate(id = row_number()) |>
  relocate(id) |>
  slice(7:2074) |>  #tail()
  filter(!str_detect(text, "-[0-9]{1,}-")) |>
  mutate(
    orden = case_when(
    str_detect(text, "Order [A-Z]{1,}")  ~ str_trim(text) |> str_squish(),
    TRUE ~ NA_character_),
    familia = case_when(
      str_detect(text, "Family [A-Z]{1,}") ~ str_trim(text) |>  str_squish(),
      TRUE ~ NA_character_)
  ) |>
  #select(orden, familia) |>
  tidyr::fill(orden, familia, .direction = "down") |>
  mutate(orden = str_remove(orden, "Order ")) |>
  mutate(fam_ingles = stringr.plus:::str_extract_between(familia, ": ", " /")) |>
  mutate(fam_spa = stringr.plus::str_extract_after(familia, "/ ")) |>
  mutate(familia = str_extract(familia, " [A-Z]{1,}:") |>
           str_squish() |>
           str_trim() |>
           str_to_sentence() |>
           tm::removePunctuation()) |>
  #select(1:2) |>
  mutate(text = str_trim(text)) |>
  mutate(text = str_replace_all(text, "\\s +", " -bird- ")) |>
  filter(str_detect(text, "-bird-")) |>
  separate(text,
           c("scientific_name", "english_name", "spanish_name"),
           sep = " -bird- ",
           remove = FALSE) |>
  select(id, text, orden, familia,
         scientific_name, english_name, spanish_name,
         everything()) |>
  mutate(text =  str_replace_all(text,
                                 " -bird- ",
                                 " / "))


bird_of_peru_list |>
  writexl::write_xlsx("data/raw_data_bird_of_peru.xlsx")


# -------------------------------------------------------------------------
# aves del peru libro

library(pdftools)
library(tabulizer)
library(tidyverse)
#list.files(pattern = "\\.pdf$")
tdf <- pdf_text("Aves de Perú 2007 (1).pdf")
length(tdf)
laminas <- grep("LÁMINA",
                tdf,
                value = TRUE)

read_bird_of_peru <- function(x){
  unlist_text <- str_split(laminas[45],
                           "\n") |>
    unlist()
  start_regex <- "[0-9]{1,} BofPeru Plates [0-9]{1,}-[0-9]{1,} pp[0-9]{1,}-[0-9]{1,} Spain:Peru/[0-9]{1,}/[0-9]{1,}:[0-9]{1,}\\s+Page [0-9]{1,}"
  start_regex_2 <- "[0-9]{1,} BofPeru Plates [0-9]{1,}-[0-9]{1,} pp[0-9]{1,}-[0-9]{1,} Spain:Peru\\s+[0-9]{1,}/[0-9]{1,}/[0-9]{1,}\\s+[0-9]{1,}:[0-9]{1,}\\s+Page [0-9]{1,}"
  unlist_text_1 <- gsub("\\s+ [0-9]{1,}",
                        "",
                        unlist_text)
  unlist_text_1 <- gsub("\\s+ LÁMINA",
                        "",
                        unlist_text_1)
  unlist_text_1 <- gsub(start_regex,
                        "",
                        unlist_text_1)
  unlist_text_1 <- gsub(start_regex_2,
                        "",
                        unlist_text_1)
  unlist_text_1
  unlist_text_1 <- unlist_text_1[nchar(unlist_text_1) != 0]
  unlist_text_1
  unlist_text_1 <- trimws(unlist_text_1)
  unlist_text_1
  unlist_text_1 <- gsub(" \\* ",
                        " asterisco ",
                        unlist_text_1)
  species <-
    unique(grep("[A-Z]{1,} [A-Z]{1,}",
                  unlist_text_1,
                  value = TRUE))
  species
  separadores <- paste0(" /separacion_sp/ ", species, " /parrafo/")
  separadores[1] <- gsub(" /separacion_sp/ ",
                         " /start/ ",
                         separadores[1])
  separadores
  new_text <- mgsub::mgsub(paste0(unlist_text_1, collapse = " "),
                           pattern = species,
                           replacement = separadores)
  new_text |>
    str_split(" /separacion_sp/ ") |>
    unlist()
}
muestra <- laminas[c(1:43, 45:100)]
length(laminas)
class(muestra)
muestra[1]
bird_of_peru_data1 <- map(laminas[1:43],
                             ~read_bird_of_peru(.))
bird_of_peru_data2 <- map(laminas[45:100],
                          ~read_bird_of_peru(.))
bird_of_peru_data3 <- map(laminas[101:158],
                          ~read_bird_of_peru(.))
bird_of_peru_data4 <- map(laminas[161:219], # 159 160 220
                          ~read_bird_of_peru(.))

bird_of_peru_data5 <- map(laminas[221:250][-28], #248
                          ~read_bird_of_peru(.))

bird_of_peru_data6 <- map(laminas[253:258],
                          ~read_bird_of_peru(.))
bird_of_peru_data7 <- map(laminas[260:261],
                          ~read_bird_of_peru(.))#262
bird_of_peru_data8 <- map(laminas[263:264], #265
                          ~read_bird_of_peru(.))
bird_of_peru_data9 <- map(laminas[266:303],
                          ~read_bird_of_peru(.))

data <- tibble::tibble(data = c(bird_of_peru_data6,
                                bird_of_peru_data7,
                                bird_of_peru_data8,
                                bird_of_peru_data9) |>
                                  unlist())
data  |>
  writexl::write_xlsx("data/raw_aves_peru_2.xlsx")


# -------------------------------------------------------------------------
#read_bird_of_peru <- function(x){
  unlist_text <- str_split(laminas[265],
                           "\n") |>
    unlist()
  start_regex <- "[0-9]{1,} BofPeru Plates [0-9]{1,}-[0-9]{1,} pp[0-9]{1,}-[0-9]{1,} Spain:Peru/[0-9]{1,}/[0-9]{1,}:[0-9]{1,}\\s+Page [0-9]{1,}"
  start_regex_2 <- "[0-9]{1,} BofPeru Plates [0-9]{1,}-[0-9]{1,} pp[0-9]{1,}-[0-9]{1,} Spain:Peru\\s+[0-9]{1,}/[0-9]{1,}/[0-9]{1,}\\s+[0-9]{1,}:[0-9]{1,}\\s+Page [0-9]{1,}"
  unlist_text_1 <- gsub("\\s+ [0-9]{1,}",
                        "",
                        unlist_text)
  unlist_text_1 <- gsub("\\s+ LÁMINA",
                        "",
                        unlist_text_1)
  unlist_text_1 <- gsub(start_regex,
                        "",
                        unlist_text_1)
  unlist_text_1 <- gsub(start_regex_2,
                        "",
                        unlist_text_1)
  unlist_text_1 <- gsub(" \\* ",
                        " asterisco ",
                        unlist_text_1)
  #unlist_text_1 <- gsub("\\[TANGARA SAYACA Thraupis sayaca\\] asterisco 16–17.5 cm",
  #                      "TANGARA SAYACA Thraupis sayaca asterisco 16–17.5 cm"  ,
  #                      unlist_text_1)
  unlist_text_1 <- gsub( "TA N G A R A S - D E - M O N TA Ñ A \\( A N I S O G N AT H U S \\,",
                         "TANGARAS - DE - MONTAÑA ANISOGNATHUS , IRIDOSORNIS",
                        unlist_text_1)
  unlist_text_1 <- unlist_text_1[nchar(unlist_text_1) != 0]
  unlist_text_1 <- trimws(unlist_text_1)
  unlist_text_1

  species <-
    unique(grep("[A-Z]{1,} [A-Z]{1,}",
                unlist_text_1,
                value = TRUE))
  species
  species <- species[-3]
  species
  separadores <- paste0(" /separacion_sp/ ", species, " /parrafo/")
  separadores[1] <- gsub(" /separacion_sp/ ",
                         " /start/ ",
                         separadores[1])
  separadores <- gsub("\\[","", separadores)
  separadores <- gsub("\\]","", separadores)
  separadores
  separadores |>  length()
  new_text <- mgsub::mgsub(paste0(unlist_text_1, collapse = " "),
                           pattern = species,
                           replacement = separadores)
  new_text |>
    str_split(" /separacion_sp/ ") |>
    unlist()
  lamina_265 <- new_text |>
    str_split(" /separacion_sp/ ") |>
    unlist()
  tibble::tibble(data = lamina_265) |>
    writexl::write_xlsx("data/raw_aves_peru_lamina_265.xlsx")

#}


# -------------------------------------------------------------------------
files <- list.files("data",
           pattern = "raw_aves",
           full.names = TRUE)

data_raw <- map_dfr(files,
                    ~readxl::read_xlsx(.) |>
                      dplyr::mutate(filename = .) |>
                      dplyr::relocate(filename))
data_aves_peru <- data_raw |>
  mutate(titulos = stringr.plus::str_extract_before(data,
                                                    " /parrafo/ "),
         parrafo = stringr.plus::str_extract_after(data,
                                                   " /parrafo/ ")) |>
  mutate(lamina = case_when(
    str_detect(titulos, "/start/") ~ titulos,
    TRUE ~ NA_character_
  )) |>
  mutate(lamina = str_remove(lamina, "/start/") |>
           str_trim() |>
           str_squish()) |>
  mutate(nombres = case_when(
    !str_detect(titulos, "/start/") ~ titulos,
    TRUE ~ NA_character_
  )) |>
  rowwise() |>
  mutate(nombre_comun = paste0(regmatches(nombres,
                                                      gregexpr("\\b[A-Z]+\\b",
                                                               nombres)) |>
                                             unlist(), collapse = " " )
) |>
  #select(nombres, nombre_comun) |>
  mutate(nombres_cientifico = str_extract(nombres,
                                          "[A-Z]{1}[a-z]{1,} [a-z]{1,}")) |>
  #mutate(lengt_word = stringi::stri_count_words(nombres)) |>
  mutate(medidas = str_remove_all(nombres,
                              "[A-Z]{1,}|[a-z]{1,}") |>
           str_trim() |>
           str_squish())
data_aves_peru |>
writexl::write_xlsx("data/raw_data_peru_aves_all.xlsx")
