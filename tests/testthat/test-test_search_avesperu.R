# test_search_avesperu_2.R

library(testthat)

test_that("search_avesperu returns expected results for multiple species", {
  result <- search_avesperu(c("Patagioenas picazuros", "Columba livia",
                                "Chordeiles nacunda", "Laterallus albigularis"),
                            return_details = TRUE)

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
  result <- search_avesperu("Falco sparverius", return_details = TRUE)

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



# Crear un archivo de prueba para la función search_avesperu
test_that("search_avesperu behaves as expected", {

  # Caso 1: Entrada válida con nombres exactos
  splist <- c("Falco sparverius", "Crypturellus soui")
  result <- search_avesperu(splist, return_details = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(splist))
  expect_equal(result$name_submitted, splist)
  expect_true(all(!is.na(result$accepted_name)))

  # Caso 2: Entrada válida con nombres aproximados
  splist <- c("Falko sparverius", "Crypturelus soui")
  result <- search_avesperu(splist, max_distance = 0.2, return_details = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(splist))
  expect_true(all(!is.na(result$accepted_name)))

  # Caso 3: Nombres no encontrados
  splist <- c("Nonexistent species", "Another fake bird")
  result <- search_avesperu(splist, return_details = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), length(splist))
  expect_true(all(is.na(result$accepted_name)))

  # Caso 4: Validación de entradas incorrectas
  expect_error(search_avesperu(123), "'splist' must be a character vector or a factor.")
  expect_error(search_avesperu(list("Falco sparverius"),
                               return_details = TRUE),
               "'splist' must be a character vector or a factor.")


  # Caso 7: Datos de salida correctos
  splist <- c("Falco sparverius")
  result <- search_avesperu(splist, return_details = TRUE)

  expect_equal(result$name_submitted[1], "Falco sparverius")
  expect_true(!is.na(result$order_name[1]))
  expect_true(!is.na(result$family_name[1]))
  expect_true(!is.na(result$english_name[1]))
  expect_true(!is.na(result$spanish_name[1]))
  expect_true(!is.na(result$status[1]))
})
