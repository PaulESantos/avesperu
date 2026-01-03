## ==============================================================================
## CONSTRUCCIÓN DEL DATASET aves_peru_2025_v5
## ==============================================================================
## Construye el objeto `aves_peru_2025_v5` a partir de la lista oficial
## de las aves del Perú (Plenge & Angulo, versión 29-12-2025) y lo
## guarda como data interna del paquete.

library(tidyverse)
library(readxl)
library(janitor)
library(usethis)

## ------------------------------------------------------------------------------
## METADATOS DE LA FUENTE
## ------------------------------------------------------------------------------

# Datos publicados el 29 de diciembre del 2025
# LISTA DE LAS AVES DEL PERÚ
# Por/by Manuel A. Plenge & Fernando Angulo
# Versión: 29 de diciembre de 2025
#
# Para la leyenda del estatus y conteos totales, visite:
#   https://sites.google.com/site/boletinunop/checklist
#
# Si detecta errores, omisiones u otros, escribir a F. Angulo:
#   chamaepetes@gmail.com
#
# Cita sugerida:
#   Plenge, M. A. & F. Angulo. Versión [fecha].
#   Lista de las aves del Perú / List of the birds of Peru.
#   Unión de Ornitólogos del Perú:
#   https://sites.google.com/site/boletinunop/checklist
#
# Se ha seguido el orden taxonómico vigente al 22 de diciembre del 2025
# del South American Checklist Committee (SACC:
#   http://www.museum.lsu.edu/~Remsen/SACCBaseline.htm),
# y se adopta su criterio de inclusión para el Perú.

## ------------------------------------------------------------------------------
## CONSTANTES DE VERSIÓN
## ------------------------------------------------------------------------------

VERSION_DATE <- "29 de diciembre de 2025"
SACC_DATE    <- "22 de diciembre de 2025"
AUTHORS      <- c("Manuel A. Plenge", "Fernando Angulo")
CONTACT      <- "chamaepetes@gmail.com"
SOURCE_URL   <- "https://sites.google.com/site/boletinunop/checklist"

## ------------------------------------------------------------------------------
## LECTURA Y LIMPIEZA BÁSICA
## ------------------------------------------------------------------------------


raw_path <- "org_data/Lista de las aves del Peru 29 dic 2025 web.xlsx"

# Verificar que el archivo existe
if (!file.exists(raw_path)) {
  stop("Archivo no encontrado: ", raw_path, call. = FALSE)
}

aves_peru_raw <- read_excel(raw_path, skip = 18) |>
  clean_names() |>
  # Renombrar columnas con nombres descriptivos en inglés
  set_names(
    c(
      "order_name", "family_name", "genus", "species_epithet",
      "scientific_name", "spanish_name", "english_name", "status"
    )
  ) |>
  # Limpiar espacios en blanco
  mutate(
    across(
      everything(),
      ~ stringr::str_trim(.x)
    )
  ) |>
  # Remover filas sin nombre científico
  filter(!is.na(scientific_name) & scientific_name != "")

message("Datos importados: ", nrow(aves_peru_raw), " especies")

## ------------------------------------------------------------------------------
## VALIDACIÓN: DUPLICADOS POR NOMBRE CIENTÍFICO
## ------------------------------------------------------------------------------


dup_sci <- aves_peru_raw |>
  count(scientific_name) |>
  filter(n > 1)

if (nrow(dup_sci) > 0) {
  stop(
    "Se encontraron nombres científicos duplicados:\n",
    paste(dup_sci$scientific_name, collapse = ", "),
    call. = FALSE
  )
}

message("No se encontraron duplicados")

## ------------------------------------------------------------------------------
## DEFINICIÓN DE CATEGORÍAS DE ESTATUS
## ------------------------------------------------------------------------------

status_categories <- tibble::tribble(
  ~code, ~spanish,        ~english,       ~description,
  "E",   "Endémico",      "Endemic",      "Especie endémica de Perú hasta que se publique registro fuera de fronteras",
  "NB",  "Migratorio",    "Migratory",    "Especies que ocurren regularmente solo en período no reproductivo",
  "V",   "Divagante",     "Vagrant",      "Especies que ocurren ocasionalmente; no parte de la avifauna habitual",
  "IN",  "Introducido",   "Introduced",   "Introducidas por humanos con poblaciones reproductivas autosuficientes",
  "U",   "No confirmado", "Unconfirmed",  "Registros no confirmados: observaciones, especímenes dudosos, evidencia no publicada",
  "EX",  "Extirpado",     "Extirpated",   "Especies extintas o extirpadas de Perú",
  "X",   "Residente",     "Resident",     "Especies residentes"
)

## ------------------------------------------------------------------------------
## VALIDACIÓN: CÓDIGOS DE ESTATUS
## ------------------------------------------------------------------------------


unknown_status <- setdiff(unique(aves_peru_raw$status), status_categories$code)

if (length(unknown_status) > 0) {
  stop(
    "Códigos de estatus desconocidos encontrados:\n",
    paste(unknown_status, collapse = ", "),
    call. = FALSE
  )
}

message("Todos los códigos de estatus son válidos")

## ------------------------------------------------------------------------------
## MAPEO DE CÓDIGOS A ETIQUETAS
## ------------------------------------------------------------------------------

# Crear diccionario código -> etiqueta en español
status_map <- status_categories |>
  select(code, spanish) |>
  deframe()
status_map
## ------------------------------------------------------------------------------
## CONSTRUCCIÓN DEL OBJETO FINAL
## ------------------------------------------------------------------------------

aves_peru_2025_v5 <- aves_peru_raw |>
  mutate(
    status_code = status,                # conservar código original
    status      = dplyr::recode(status,  # etiqueta en español
                                !!!status_map)
  ) |>
  select(
    order_name,
    family_name,
    genus,
    species_epithet,
    scientific_name,
    english_name,
    spanish_name,
    status,       # etiqueta en español
    status_code   # código original de la lista
  )

message("Dataset construido: ", nrow(aves_peru_2025_v5), " especies")

## ------------------------------------------------------------------------------
## AÑADIR ATRIBUTOS DE METADATA
## ------------------------------------------------------------------------------

message("Añadiendo metadatos al dataset...")

# Atributos principales
attr(aves_peru_2025_v5, "version_date") <- VERSION_DATE
attr(aves_peru_2025_v5, "sacc_date")    <- SACC_DATE
attr(aves_peru_2025_v5, "authors")      <- AUTHORS
attr(aves_peru_2025_v5, "contact")      <- CONTACT
attr(aves_peru_2025_v5, "source_url")   <- SOURCE_URL

# Metadatos adicionales
attr(aves_peru_2025_v5, "created_on")   <- Sys.time()

# Estadísticas del dataset
species_counts <- aves_peru_2025_v5 |>
  count(status, name = "n_species") |>
  arrange(desc(n_species))
species_counts



## ------------------------------------------------------------------------------
## VERIFICAR ATRIBUTOS
## ------------------------------------------------------------------------------

message("Verificando atributos del dataset...")

required_attrs <- c(
  "version_date", "sacc_date", "authors", "contact", "source_url",
  "created_on"
)

for (attr_name in required_attrs) {
  attr_value <- attr(aves_peru_2025_v5, attr_name)

  if (is.null(attr_value)) {
    warning("Atributo faltante: ", attr_name, call. = FALSE)
  } else {
    # Formatear el valor según su tipo y longitud
    display_value <- if (length(attr_value) == 1) {
      # Valores únicos
      if (inherits(attr_value, "POSIXct")) {
        format(attr_value, "%Y-%m-%d %H:%M:%S")
      } else {
        as.character(attr_value)
      }
    } else if (length(attr_value) <= 3 && is.atomic(attr_value)) {
      # Vectores cortos (como authors)
      paste(attr_value, collapse = ", ")
    } else {
      # Objetos complejos (listas, data frames, etc.)
      sprintf("[%s, length=%d]", class(attr_value)[1], length(attr_value))
    }

    message("  - ", attr_name, ": ", display_value)
  }
}
## ------------------------------------------------------------------------------
## GUARDAR DATOS EN EL PAQUETE
## ------------------------------------------------------------------------------

usethis::use_data(
  aves_peru_2025_v5,
  compress  = "xz",
  overwrite = TRUE,
  version   = 3  # Para compatibilidad con R >= 3.5.0
)


