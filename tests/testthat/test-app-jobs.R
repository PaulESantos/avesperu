test_that("background jobs resolve the current source and preserve provenance", {
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  job <- start_app_job(
    pasted_name_records("Falco CF. sparverius\n\nTinamus major"),
    list(
      mode = "resolve",
      max_distance = 0,
      batch_size = 1,
      parallel = FALSE,
      n_cores = NULL
    )
  )
  withr::defer(stop_app_job(job))
  job$wait(timeout = 30000)
  expect_identical(job$is_alive(), FALSE)
  out <- job$get_result()
  expect_identical(out$results$source_row, c(1L, 3L))
  expect_identical(out$results$review_reason[1], "qualifier")
  expect_identical(
    out$metadata$value[out$metadata$field == "effective_batches"],
    "2"
  )
  expect_identical(
    out$metadata$value[out$metadata$field == "reference_id"],
    "aves_peru_2026_v1"
  )
})

test_that("completed session exports include review flags and source rows", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("callr")
  skip_if_not_installed("later")
  shiny::testServer(avesperu_app_server, {
    session$setInputs(
      names_text = "Falco CF. sparverius",
      processing_mode = "resolve",
      matching_mode = "exact",
      batch_size = 250,
      use_parallel = FALSE,
      n_cores = 0
    )
    session$setInputs(submit_names = 1)
    deadline <- Sys.time() + 20
    while (is.null(processed_results()) && Sys.time() < deadline) {
      later::run_now(0.1)
      session$flushReact()
    }
    expect_type(processed_results(), "list")
    csv <- utils::read.csv(output$download_csv)
    tsv <- utils::read.delim(output$download_tsv)
    expect_identical(csv$submitted_name, "Falco CF. sparverius")
    expect_identical(csv$review_flag, TRUE)
    expect_identical(csv$source_row, 1L)
    expect_identical(tsv$review_reason, "qualifier")
    metadata <- utils::read.csv(output$download_metadata)
    expect_match(
      metadata$value[metadata$field == "reference_content_md5"],
      "^[a-f0-9]{32}$"
    )
    if (
      requireNamespace("writexl", quietly = TRUE) &&
        requireNamespace("readxl", quietly = TRUE)
    ) {
      xlsx <- readxl::read_excel(output$download_xlsx, sheet = "results")
      expect_identical(xlsx$review_reason, "qualifier")
    }
    session$setInputs(clear_all = 1)
    expect_null(processed_results())
    blocked <- tryCatch(output$download_csv, shiny.silent.error = function(e) {
      "blocked"
    })
    expect_identical(blocked, "blocked")
  })
})
