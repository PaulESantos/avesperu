test_that("avesperu_tab dataset has the expected characteristics", {
  # Check the dimensions of the dataset
  expect_equal(dim(avesperu_tab), c(1892, 6))

  # Check the first few rows of the dataset
  expected_head <- data.frame(
    scientific_name = c(
      "Rhea pennata",
      "Nothocercus julius",
      "Nothocercus bonapartei",
      "Nothocercus nigrocapillus",
      "Tinamus tao",
      "Tinamus osgoodi"
    ),
    english_name = c(
      "Lesser Rhea",
      "Tawny-breasted Tinamou",
      "Highland Tinamou",
      "Hooded Tinamou",
      "Gray Tinamou",
      "Black Tinamou"
    ),
    spanish_name = c(
      "Ñandú Petizo",
      "Perdiz de Pecho Leonado",
      "Perdiz Montesa",
      "Perdiz de Cabeza Negra",
      "Perdiz Gris",
      "Perdiz Negra"
    ),
    order = c(
      "Rheiformes",
      "Tinamiformes",
      "Tinamiformes",
      "Tinamiformes",
      "Tinamiformes",
      "Tinamiformes"
    ),
    family = c(
      "Rheidae",
      "Tinamidae",
      "Tinamidae",
      "Tinamidae",
      "Tinamidae",
      "Tinamidae"
    ),
    status = c("nill", "nill", "nill", "nill", "nill", "nill")
  )

  expect_equal(avesperu_tab[1:6, ], expected_head)
})
