# Custom expectations for avesperu package

#' Expect Valid Search Result
#'
#' Validates that a result from search_avesperu() has the correct structure
#' when return_details = TRUE
#'
#' @param result The result object to validate
#'
#' @examples
#' \dontrun{
#' result <- search_avesperu("Falco sparverius", return_details = TRUE)
#' expect_valid_search_result(result)
#' }
#'
#' @keywords internal
expect_valid_search_result <- function(result) {
  testthat::expect_s3_class(result, "data.frame")
  testthat::expect_named(
    result,
    c("name_submitted", "accepted_name", "order_name", "family_name",
      "english_name", "spanish_name", "status", "dist")
  )
  testthat::expect_type(result$name_submitted, "character")
  testthat::expect_type(result$accepted_name, "character")
  testthat::expect_type(result$order_name, "character")
  testthat::expect_type(result$family_name, "character")
  testthat::expect_type(result$english_name, "character")
  testthat::expect_type(result$spanish_name, "character")
  testthat::expect_type(result$status, "character")
  testthat::expect_type(result$dist, "character")
}

#' Expect Matched Species Result
#'
#' Validates that a search result contains a valid species match
#' (no NA values for matched fields)
#'
#' @param result The result row to validate
#' @param expected_name The expected accepted species name
#'
#' @keywords internal
expect_matched_species <- function(result, expected_name = NULL) {
  testthat::expect_false(is.na(result$accepted_name))
  testthat::expect_false(is.na(result$order_name))
  testthat::expect_false(is.na(result$family_name))
  testthat::expect_false(is.na(result$status))

  if (!is.null(expected_name)) {
    testthat::expect_equal(result$accepted_name, expected_name)
  }
}

#' Expect Unmatched Species Result
#'
#' Validates that a search result represents an unmatched species
#' (all match-related fields are NA)
#'
#' @param result The result row to validate
#'
#' @keywords internal
expect_unmatched_species <- function(result) {
  testthat::expect_true(is.na(result$accepted_name))
  testthat::expect_true(is.na(result$order_name))
  testthat::expect_true(is.na(result$family_name))
  testthat::expect_true(is.na(result$english_name))
  testthat::expect_true(is.na(result$spanish_name))
  testthat::expect_true(is.na(result$status))
  testthat::expect_true(is.na(result$dist))
}

#' Expect Standardized Name Format
#'
#' Validates that a name follows the standardized format:
#' - First letter of genus capitalized
#' - First letter of species lowercase
#' - Single spaces between words
#'
#' @param name The name to validate
#'
#' @keywords internal
expect_standardized_name <- function(name) {
  # Verificar que no sea NA
  testthat::expect_false(is.na(name))

  # Verificar que no tenga espacios múltiples
  testthat::expect_false(grepl("\\s{2,}", name))

  # Verificar que no tenga espacios al inicio o final
  testthat::expect_false(grepl("^\\s|\\s$", name))

  # Verificar formato: Primera palabra capitalizada, segunda minúscula
  if (grepl("\\s", name)) {
    parts <- strsplit(name, "\\s")[[1]]
    first_word <- parts[1]
    second_word <- parts[2]

    # Primera palabra: primer carácter mayúscula, resto minúscula
    testthat::expect_match(first_word, "^[A-Z][a-z]*$")

    # Segunda palabra: primer carácter minúscula
    testthat::expect_match(second_word, "^[a-z]")
  }
}
