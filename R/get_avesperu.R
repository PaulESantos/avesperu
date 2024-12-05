#' Search for Bird Species Data in the Birds of Peru Dataset
#'
#' This function searches for bird species information in the dataset provided by
#' the `avesperu` package, given a list of species names. It supports approximate
#' (fuzzy) matching to handle typographical errors or minor variations in the
#' species names. The function returns detailed information for each species,
#' including taxonomic data, common names, and status.
#'
#' @param splist A character vector containing the names of bird species to search for.
#'   Names can include minor variations or typos.
#' @param max_distance Numeric. The maximum allowable distance for fuzzy matching,
#'   which can either be a proportion (0 < max_distance < 1) or an integer representing
#'   the maximum number of allowed differences. Defaults to 0.1.
#'
#' @details
#' The function performs the following steps:
#' 1. Validates the input, ensuring that `splist` is a character vector or a factor.
#' 2. Standardizes species names and identifies duplicate entries in the list.
#' 3. For each unique species name, it searches for matches in the dataset using
#'    approximate string matching (`agrep`), with a customizable `max_distance`.
#' 4. Retrieves the taxonomic and common name data for the closest matching species.
#'
#' If no matches are found for a species, the corresponding row in the output will
#' contain `NA` values.
#'
#' @return A data frame with the following columns:
#' \describe{
#'   \item{name_submitted}{The species name provided as input.}
#'   \item{accepted_name}{The closest matching species name from the dataset, or `NA` if no match is found.}
#'   \item{order_name}{The taxonomic order of the species.}
#'   \item{family_name}{The taxonomic family of the species.}
#'   \item{english_name}{The common name of the species in English.}
#'   \item{spanish_name}{The common name of the species in Spanish.}
#'   \item{status}{The conservation or other status of the species.}
#'   \item{dist}{The computed distance between the submitted name and the matched name.}
#' }
#'
#' @examples
#' # Example: Search for bird species in the dataset
#' splist <- c("Falco sparverius", "Tinamus osgodi", "Crypturellus soui",
#'             "Thraupis palmarum", "Thamnophilus praecox")
#' search_avesperu(splist)
#'
#' @export
search_avesperu <- function(splist, max_distance = 0.1) {
  # Validación de entrada

  if (!is.character(splist) && !is.factor(splist)) {
    stop("'splist' must be a character vector or a factor.")
  }

  # Convertir factores a caracteres
  if (is.factor(splist)) {
    splist <- as.character(splist)
  }

  # Estandarizar nombres y encontrar duplicados
  splist_st <- standardize_names(splist)
  dupes_splist_st <- find_duplicates(splist_st)
  if (length(dupes_splist_st) != 0) {
    message("The following names are repeated in the 'splist': ",
            paste(dupes_splist_st, collapse = ", "))
  }
  splist_std <- unique(splist_st)

  # Crear contenedor de salida
  output_matrix <- matrix(NA, nrow = length(splist_std), ncol = 8)
  colnames(output_matrix) <- c("name_submitted",
                               "accepted_name",
                               "order_name",
                               "family_name",
                               "english_name",
                               "spanish_name",
                               "status",
                               "dist")

  # Iterar sobre los nombres estandarizados
  for (i in seq_along(splist_std)) {
    # Calcular distancia máxima
    if (max_distance > 0 && max_distance < 1) {
      max_distance_fixed <- ceiling(nchar(splist_std[i]) * max_distance)
    } else {
      max_distance_fixed <- as.integer(max_distance)
    }

    # Buscar coincidencias aproximadas
    matches <- agrep(splist_std[i],
                     avesperu::aves_peru_2024_v2$scientific_name,
                     max.distance = max_distance_fixed,
                     value = TRUE)

    if (length(matches) == 0) {
      # No hay coincidencias
      valid_matches <- NA
      dis_value <- NA
      row_data <- matrix(NA, nrow = 1, ncol = 5) # Crear una fila vacía
      colnames(row_data) <- c("order_name", "family_name", "english_name",
                              "spanish_name", "status")
    } else {
      # Calcular distancias y filtrar coincidencias válidas
      dis_value <- as.numeric(utils::adist(splist_std[i], matches))
      valid_matches <- matches[dis_value <= max_distance_fixed]
      valid_distances <- dis_value[dis_value <= max_distance_fixed]

      if (length(valid_matches) == 0) {
        # Sin coincidencias válidas
        valid_matches <- NA
        dis_value <- NA
        row_data <- matrix(NA, nrow = 1, ncol = 5)
        colnames(row_data) <- c("order_name", "family_name", "english_name",
                                "spanish_name", "status")
      } else {
        # Extraer datos de la coincidencia más cercana
        row_data <- as.matrix(avesperu::aves_peru_2024_v2[
          avesperu::aves_peru_2024_v2$scientific_name %in% valid_matches,
          c("order_name", "family_name", "english_name", "spanish_name", "status")
        ])
        row_data <- row_data[1, , drop = FALSE]
        dis_value <- valid_distances[1]
      }
    }

    # Llenar la matriz de salida
    output_matrix[i, ] <- c(
      splist_std[i],                                # Nombre original
      if (!is.na(valid_matches[1])) valid_matches[1] else NA, # Nombre aceptado
      row_data[1, "order_name"],
      row_data[1, "family_name"],
      row_data[1, "english_name"],
      row_data[1, "spanish_name"],
      row_data[1, "status"],
      dis_value                                    # Distancia
    )
  }

  # Convertir a data.frame
  output <- as.data.frame(output_matrix, stringsAsFactors = FALSE)
  colnames(output) <- c("name_submitted", "accepted_name", "order_name",
                        "family_name", "english_name", "spanish_name",
                        "status", "dist")
  rownames(output) <- NULL
  return(output)
}
