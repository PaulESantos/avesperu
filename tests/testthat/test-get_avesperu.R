test_that("empty inputs preserve the public contract and audit schema", {
  expect_identical(search_avesperu(character()), character())
  out <- search_avesperu(character(), return_details = TRUE)
  expect_identical(dim(out), c(0L, 8L))
  expect_identical(
    vapply(out, typeof, character(1)),
    setNames(rep("character", 8), names(out))
  )
  expect_identical(nrow(attr(out, "reconciliation")), 0L)
  expect_identical(nrow(build_resolution_results(character())), 0L)
  expect_identical(nrow(build_parse_results(character())), 0L)
})

test_that("ambiguous candidates never depend on reference order", {
  db <- current_checklist()[1:2, ]
  db$scientific_name <- c("Testus alba", "Testus albe")
  forward <- search_with_agrep("Testus albi", db, db$scientific_name, 1)
  db <- db[2:1, ]
  reverse <- search_with_agrep("Testus albi", db, db$scientific_name, 1)
  expect_identical(forward, reverse)
  expect_identical(forward$accepted_name, NA_character_)
  expect_identical(forward$status, NA_character_)
  expect_identical(forward$match_type, "ambiguous")
  expect_identical(forward$candidate_count, 2L)
  expect_identical(forward$candidates, "Testus alba; Testus albe")
  local_mocked_bindings(current_checklist = function() db)
  out <- search_avesperu("Testus albi", max_distance = 1, return_details = TRUE)
  expect_identical(attr(out, "reconciliation")$match_type, "ambiguous")
  expect_identical(
    search_avesperu("Testus albi", max_distance = 1),
    NA_character_
  )
})

test_that("qualifiers retain original values and require review", {
  names <- c("Falco CF. sparverius", "Falco aff. sparverius")
  result <- build_resolution_results(names)
  expect_identical(result$submitted_name, names)
  expect_identical(result$accepted_name, rep("Falco sparverius", 2))
  expect_identical(result$has_qualifier, rep(TRUE, 2))
  expect_identical(result$review_flag, rep(TRUE, 2))
  expect_identical(result$review_reason, rep("qualifier", 2))
  expect_identical(search_avesperu(names), rep(NA_character_, 2))
  warnings <- character()
  hybrid <- withCallingHandlers(
    build_resolution_results("Falco x sparverius"),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1L)
  expect_identical(hybrid$review_reason, "hybrid")
})

test_that("invalid scalar options fail before matching", {
  invalid <- list(
    max_distance = list(NA_real_, NaN, Inf, -Inf, 1.5, 2^32),
    batch_size = list(NA_real_, Inf, 1.5, 0),
    n_cores = list(NA_real_, Inf, 1.5, 0),
    return_details = list(NA, logical(), c(TRUE, FALSE)),
    parallel = list(NA)
  )
  expect_snapshot({
    for (arg in names(invalid)) {
      for (value in invalid[[arg]]) {
        args <- c(list(splist = "Falco sparverius"), setNames(list(value), arg))
        cat(
          arg,
          ": ",
          tryCatch(
            {
              do.call(search_avesperu, args)
              "ACCEPTED"
            },
            error = function(e) conditionMessage(e)
          ),
          "\n",
          sep = ""
        )
      }
    }
  })
})

test_that("distance boundaries retain documented rounding", {
  db <- current_checklist()[1, ]
  db$scientific_name <- "Testus alba"
  expect_identical(
    search_with_agrep("Testus albi", db, db$scientific_name, 0)$match_type,
    "unmatched"
  )
  expect_identical(
    search_with_agrep("Testus albi", db, db$scientific_name, 0.01)$dist,
    "1"
  )
  expect_identical(
    search_with_agrep("Testus albi", db, db$scientific_name, 1)$dist,
    "1"
  )
})
