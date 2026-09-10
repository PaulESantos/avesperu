test_that("delimited imports retain headerless first rows, missing values and record numbers", {
  for (ext in c("csv", "tsv")) {
    path <- withr::local_tempfile(fileext = paste0(".", ext))
    writeLines(c("Falco sparverius", "", "NA", "Tinamus osgoodi"), path)
    result <- read_avesperu_name_file(path, records = TRUE)
    expect_identical(
      result$submitted_name,
      c("Falco sparverius", "", NA_character_, "Tinamus osgoodi")
    )
    expect_identical(result$source_row, 1:4)
    writeLines("Falco sparverius", path)
    expect_identical(read_avesperu_name_file(path), "Falco sparverius")
    writeLines(c("scientific_name", "Falco sparverius"), path)
    expect_identical(
      read_avesperu_name_file(path, records = TRUE)$source_row,
      2L
    )
    expect_identical(
      read_avesperu_name_file(path, header = "no"),
      c("scientific_name", "Falco sparverius")
    )
  }
})

test_that("ambiguous columns require an explicit selection", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("id,bird", "1,Falco sparverius"), path)
  expect_snapshot(error = TRUE, read_avesperu_name_file(path))
  result <- read_avesperu_name_file(
    path,
    header = "yes",
    column = 2,
    records = TRUE
  )
  expect_identical(result$submitted_name, "Falco sparverius")
  expect_identical(result$source_row, 2L)
})

test_that("Excel imports retain blank worksheet rows and headerless species", {
  skip_if_not_installed("writexl")
  skip_if_not_installed("readxl")
  path <- withr::local_tempfile(fileext = ".xlsx")
  writexl::write_xlsx(
    data.frame(scientific_name = c("Falco sparverius", NA, "Tinamus major")),
    path
  )
  result <- read_avesperu_name_file(path, records = TRUE)
  expect_identical(result$source_row, 2:4)
  expect_identical(
    result$submitted_name,
    c("Falco sparverius", NA_character_, "Tinamus major")
  )
  writexl::write_xlsx(
    data.frame(x = "Falco sparverius"),
    path,
    col_names = FALSE
  )
  expect_identical(read_avesperu_name_file(path), "Falco sparverius")
})

test_that("parsing distinguishes authors, infraspecific epithets and unknown text", {
  out <- build_parse_results(c(
    "Falco sparverius Linnaeus, 1758",
    "Falco sparverius caucus",
    "Falco sparverius subsp. caucus",
    "Falco sparverius unknown trailing text"
  ))
  expect_identical(
    out$submitted_rank_guess,
    c("binomial", "infraspecific", "infraspecific", "unparsed")
  )
  expect_identical(out$submitted_author[1], "Linnaeus, 1758")
  expect_identical(out$submitted_infraspecific[1], NA_character_)
  expect_identical(out$review_flag[4], TRUE)
})

test_that("Clear invalidates results and failed uploads cannot reuse earlier data", {
  skip_if_not_installed("shiny")
  path <- withr::local_tempfile(fileext = ".txt")
  writeLines("Falco sparverius", path)
  shiny::testServer(avesperu_app_server, {
    session$setInputs(names_text = "")
    session$setInputs(
      upload_names = data.frame(datapath = path, name = "birds.txt")
    )
    expect_identical(uploaded_names(), "Falco sparverius")
    processed_results(list(
      mode = "parse",
      results = build_parse_results("Falco sparverius")
    ))
    session$setInputs(clear_all = 1, names_text = "")
    expect_null(processed_results())
    expect_length(combined_names(), 0L)
    session$setInputs(
      upload_names = data.frame(datapath = path, name = "birds.txt")
    )
    session$setInputs(
      upload_names = data.frame(datapath = path, name = "bad.ext")
    )
    expect_length(uploaded_names(), 0L)
    expect_type(upload_error(), "character")
    session$setInputs(submit_names = 1)
    expect_null(processed_results())
    expect_match(processing_status(), "Fix the uploaded file")
  })
})

test_that("changing input cancels work and stale completions cannot publish", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("later")
  killed <- 0L
  read_results <- 0L
  job <- list(
    is_alive = function() TRUE,
    kill_tree = function() {
      killed <<- killed + 1L
    },
    get_result = function() {
      read_results <<- read_results + 1L
    }
  )
  local_mocked_bindings(start_app_job = function(...) job)
  shiny::testServer(avesperu_app_server, {
    session$setInputs(
      names_text = "Falco sparverius",
      processing_mode = "parse"
    )
    session$setInputs(submit_names = 1)
    expect_match(processing_status(), "background")
    session$setInputs(names_text = "Tinamus major")
    expect_identical(killed, 1L)
    later::run_now(0.2)
    expect_identical(read_results, 0L)
    expect_null(processed_results())
  })
})

test_that("closing one session does not close a second session", {
  skip_if_not_installed("shiny")
  first <- shiny::MockShinySession$new()
  second <- shiny::MockShinySession$new()
  withr::defer(second$close())
  shiny::testServer(avesperu_app_server, session = first, {
    session$setInputs(names_text = "")
    session$setInputs(stop_app = 1)
    expect_identical(session$isClosed(), TRUE)
    expect_identical(second$isClosed(), FALSE)
  })
})

test_that("app workload limits reject excessive rows and long names", {
  expect_snapshot(
    error = TRUE,
    validate_app_input(data.frame(
      submitted_name = rep("Falco sparverius", 10001)
    ))
  )
  expect_snapshot(
    error = TRUE,
    validate_app_input(data.frame(
      submitted_name = paste(rep("x", 201), collapse = "")
    ))
  )
})
