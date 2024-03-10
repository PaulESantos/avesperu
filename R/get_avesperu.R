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
  # Defensive function here, check for user input errors
  if (is.factor(splist)) {
    splist <- as.character(splist)
  }
  # Fix species name
  splist_st <- standardize_names(splist)
  dupes_splist_st <- find_duplicates(splist_st)

  if(length(dupes_splist_st) != 0 ){
    message("The following names are repeated in the 'splist': ",
            paste(dupes_splist_st, collapse = ", "))
  }
  splist_std <- unique(splist_st)

  # create an output data container
  output_matrix <- matrix(nrow = length(splist_std), ncol = 8)
  colnames(output_matrix) <- c("name_submitted",
                               "accepted_name",
                               "english_name",
                               "spanish_name",
                               "order",
                               "family",
                               "status",
                               "dist"
  )
  # loop code to find the matching string

  for (i in seq_along(splist_std)) {
    # Standardise max distance value
    if (max_distance < 1 & max_distance > 0) {
      max_distance_fixed <- ceiling(nchar(splist_std[i]) * max_distance)
    } else {
      max_distance_fixed <- max_distance
    }

    # fuzzy and exact match
    matches <- agrep(splist_std[i],
                     avesperu::aves_peru_2024$scientific_name, # base data column
                     max.distance = max_distance_fixed,
                     value = TRUE)

       # check non matching result
    if (length(matches) == 0) {
        row_data <- rep("nill", 6)
    }
    else  if (length(matches) != 0){ # match result
      dis_value <- as.numeric(utils::adist(splist_std[i], matches))
      matches1 <- matches[dis_value <= max_distance_fixed]
      dis_val_1 <- dis_value[dis_value <= max_distance_fixed]

      if(length(matches1) == 0){
        row_data <- rep("nill", 6)
      }
      else if(length(matches1) != 0){
        row_data <- as.matrix(avesperu::aves_peru_2024[avesperu::aves_peru_2024$scientific_name %in% matches1,])
      }
    }

    # distance value
    if(is.null(nrow(row_data))){
      dis_value_1 <- "nill"
    } else{
      dis_value_1 <- utils::adist(splist_std[i], row_data[,1])
    }

    output_matrix[i, ] <-
      c(splist_std[i], row_data, dis_value_1)
  }

  # Output
  output <- as.data.frame(output_matrix)
  rownames(output) <- NULL
  return(output[output$accepted_name != "nill",])
}

