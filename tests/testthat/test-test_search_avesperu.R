# Define the test case
test_that("search_avesperu returns the correct output", {
  # Define the input vector
  splist <- c(
    "Falco sparverius",
    "Tinamus osgodi",
    "Crypturellus sooui",
    "Thraupisa palamarum"
  )

  # Call the search_avesperu function
  result <- search_avesperu(splist)
result
  # Define the expected output
  expected <- data.frame(
    name_submitted = c(
      "Falco sparverius",
      "Tinamus osgodi",
      "Crypturellus sooui",
      "Thraupisa palamarum"
    ),
    accepted_name = c(
      "Falco sparverius",
      "Tinamus osgoodi",
      "Crypturellus soui",
      "Thraupis palmarum"
    ),
    english_name = c(
      "American Kestrel",
      "Black Tinamou",
      "Little Tinamou",
      "Palm Tanager"
    ),
    spanish_name = c(
      "Cernícalo Americano",
      "Perdiz Negra",
      "Perdiz Chica",
      "Tangara de Palmeras"
    ),
    order = c(
      "Falconiformes",
      "Tinamiformes",
      "Tinamiformes",
      "Passeriformes"
    ),
    family = c(
      "Falconidae",
      "Tinamidae",
      "Tinamidae",
      "Thraupidae"
    ),
    status = c("Residente", "Residente", "Residente", "Residente"),
    dist = c("0", "1", "1", "2")
  )

  # Compare the result with the expected output
  expect_equal(result, expected)
})
