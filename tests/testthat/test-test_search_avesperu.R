# test_search_avesperu_2.R

library(testthat)

test_that("search_avesperu returns expected results for multiple species", {
  result <- search_avesperu(c("Patagioenas picazuros", "Columba livia",
                                "Chordeiles nacunda", "Laterallus albigularis"))

  # Comprobar dimensiones del resultado
  expect_equal(nrow(result), 4)
  expect_equal(ncol(result), 8)

  # Comprobar valores específicos
  expect_equal(result$name_submitted,
               c("Patagioenas picazuros", "Columba livia",
                 "Chordeiles nacunda", "Laterallus albigularis"))

  expect_equal(result$accepted_name,
               c("Patagioenas picazuro", "Columba livia",
                 "Chordeiles nacunda", "Laterallus albigularis"))

  expect_equal(result$order_name,
               c("Columbiformes", "Columbiformes",
                 "Caprimulgiformes", "Gruiformes"))

  expect_equal(result$family_name,
               c("Columbidae", "Columbidae", "Caprimulgidae", "Rallidae"))

  expect_equal(result$english_name,
               c("Picazuro Pigeon", "Rock Pigeon",
                 "Nacunda Nighthawk", "White-throated Crake"))

  expect_equal(result$spanish_name,
               c("Paloma Picazuró", "Paloma Doméstica",
                 "Chotacabras de Vientre Blanco", "Gallineta de Garganta Blanca"))

  expect_equal(result$status,
               c("Divagante", "Introducido", "Migratorio", "Divagante"))

  expect_equal(result$dist, as.character(c(1, 0, 0, 0)))
})

test_that("search_avesperu returns expected results for a single species", {
  result <- search_avesperu("Falco sparverius")

  # Comprobar dimensiones del resultado
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 8)

  # Comprobar valores específicos
  expect_equal(result$name_submitted, "Falco sparverius")
  expect_equal(result$accepted_name, "Falco sparverius")
  expect_equal(result$order_name, "Falconiformes")
  expect_equal(result$family_name, "Falconidae")
  expect_equal(result$english_name, "American Kestrel")
  expect_equal(result$spanish_name, "Cernícalo Americano")
  expect_equal(result$status, "Residente")
  expect_equal(result$dist, "0")
})


