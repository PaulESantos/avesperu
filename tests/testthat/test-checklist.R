test_that("the current reference satisfies the schema", {
  expect_no_error(validate_checklist(current_checklist()))
  corrections <- attr(current_checklist(), "component_corrections")
  expect_identical(nrow(corrections), 2L)
  expect_setequal(
    corrections$scientific_name,
    c("Pterodroma axillaris", "Diglosa melanopis")
  )
  expect_identical(
    reconcile_checklist_parts(current_checklist()),
    current_checklist()
  )
})

test_that("invalid reference tables are rejected before publishing", {
  expect_snapshot({
    for (kind in c("missing", "swapped", "duplicate", "code")) {
      db <- current_checklist()[1:3, ]
      if (kind == "missing") {
        db$family_name[1] <- NA_character_
      }
      if (kind == "swapped") {
        db$genus <- db$family_name
      }
      if (kind == "duplicate") {
        db[2, ] <- db[1, ]
      }
      if (kind == "code") {
        db$status_code[1] <- "?"
      }
      cat(
        kind,
        ": ",
        tryCatch(
          {
            validate_checklist(db)
            "ACCEPTED"
          },
          error = function(e) conditionMessage(e)
        ),
        "\n",
        sep = ""
      )
    }
  })
})

test_that("source schema follows column labels and preserves partial rows", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- withr::local_tempfile(fileext = ".xlsx")
  db <- current_checklist()[1:3, ]
  raw <- db[, c(
    "order_name",
    "family_name",
    "genus",
    "species_epithet",
    "scientific_name",
    "spanish_name",
    "english_name",
    "status_code"
  )]
  names(raw) <- c(
    "Orden",
    "Familia",
    "G\u00e9nero",
    "Especie",
    "Nombre cient\u00edfico",
    "Nombre peruano",
    "Nombre en ingl\u00e9s",
    "Estatus"
  )
  raw <- raw[, rev(seq_len(ncol(raw)))]
  writexl::write_xlsx(raw, path)
  imported <- read_checklist_source(path)
  expect_identical(imported$scientific_name, db$scientific_name)
  expect_identical(imported$genus, db$genus)
  raw[1, "Nombre cient\u00edfico"] <- NA_character_
  writexl::write_xlsx(raw, path)
  expect_identical(nrow(read_checklist_source(path)), 3L)
})
