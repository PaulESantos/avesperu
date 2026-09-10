test_that("normalization is idempotent with adjacent markers and case variants", {
  input <- c(
    "Falco CF. sparverius",
    "Falco_AFF._sparverius",
    "Falco x x sparverius",
    "Falco \u00d7 sparverius",
    "",
    NA_character_,
    "Falco affinis"
  )
  normalized <- suppressWarnings(standardize_names(input))
  expect_identical(standardize_names(normalized), normalized)
  expect_identical(normalized[1:4], rep("Falco sparverius", 4))
  expect_identical(normalized[7], "Falco affinis")
})

test_that("UNOP extraction handles formatting and chooses latest labelled update", {
  expect_identical(
    extract_unop_update_date("Actualizado: 9 de MARZO de 2026"),
    "9 de marzo de 2026"
  )
  expect_identical(
    extract_unop_update_date("Actualizada el 1\u00a0de setiembre de 2026"),
    "1 de setiembre de 2026"
  )
  expect_identical(
    extract_unop_update_date(paste(
      "Actualizado 1 de enero de 2025. Publicado 1 de enero de 2030.",
      "Actualizado 23 de marzo de 2026"
    )),
    "23 de marzo de 2026"
  )
  expect_identical(
    is.na(extract_unop_update_date("Publicado 23 de marzo de 2026")),
    TRUE
  )
  expect_identical(parse_unop_date("31 de febrero de 2026"), as.Date(NA))
  expect_identical(parse_unop_date("1 de marzo de 2026 trailing"), as.Date(NA))
})
