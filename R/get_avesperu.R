#' Retrieve Data from the List of the Birds of Peru
#'
#' This function takes a list of birds species names, searches for their data in
#' the avesperu pacakage dataset, and returns a data frame containing the relevant
#' information for each species.
#'
#' The function allows fuzzy matching for species names with a maximum
#' distance threshold to handle potential typos or variations in species names.
#'
#' @param splist A character vector containing the names of the species to search for.
#' @param max_distance The maximum allowed distance for fuzzy matching of species names.
#'   Defaults to 0.1.
#'
#' @return A data frame containing the retrieved information for each species.
#'
#' @examples
#'
#' splist <- c("Falco sparverius", "Tinamus osgodi", "Crypturellus sooui",
#'             "Thraupisa palamarum", "Thamnophilus praecox")
#'
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
      # Si no hay coincidencias
      row_data <- matrix(NA, nrow = 1, ncol = 6)
      dis_value <- NA
    } else {
      # Calcular distancias y filtrar
      dis_value <- as.numeric(utils::adist(splist_std[i], matches))
      valid_matches <- matches[dis_value <= max_distance_fixed]
      valid_distances <- dis_value[dis_value <= max_distance_fixed]

      if (length(valid_matches) == 0) {
        row_data <- matrix(NA, nrow = 1, ncol = 6)
        dis_value <- NA
      } else {
        # Extraer datos de las coincidencias válidas
        row_data <- as.matrix(avesperu::aves_peru_2024_v2[
          avesperu::aves_peru_2024_v2$scientific_name %in% valid_matches,
          c("order_name", "family_name", "english_name", "spanish_name", "status")
        ])
        row_data <- row_data[1, , drop = FALSE] # Tomar la primera coincidencia
        dis_value <- valid_distances[1]         # Distancia correspondiente
      }
    }

    # Llenar la matriz de salida
    output_matrix[i, ] <- c(
      splist_std[i],                                # Nombre original
      ifelse(is.null(row_data), NA, valid_matches[1]), # Nombre aceptado
      ifelse(is.null(row_data), NA, row_data[, "order_name"]),
      ifelse(is.null(row_data), NA, row_data[, "family_name"]),
      ifelse(is.null(row_data), NA, row_data[, "english_name"]),
      ifelse(is.null(row_data), NA, row_data[, "spanish_name"]),
      ifelse(is.null(row_data), NA, row_data[, "status"]),
      dis_value                                    # Distancia
    )
  }

  # Convertir a data.frame y limpiar salida
  output <- as.data.frame(output_matrix, stringsAsFactors = FALSE)
  colnames(output) <- c("name_submitted", "accepted_name", "order_name",
                        "family_name", "english_name", "spanish_name",
                        "status", "dist")
  output <- output[!is.na(output$accepted_name), ]
  rownames(output) <- NULL
  return(output)
}
