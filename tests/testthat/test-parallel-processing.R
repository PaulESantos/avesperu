test_that("parallel and serial batches agree on all rows and audit information", {
  input <- c(
    "Falco sparverius",
    "Falko sparverius",
    NA,
    "Invented bird",
    "Falco sparverius"
  )
  serial <- search_avesperu(
    input,
    batch_size = 1,
    parallel = FALSE,
    return_details = TRUE
  )
  parallel <- search_avesperu(
    input,
    batch_size = 1,
    parallel = TRUE,
    n_cores = 2L,
    return_details = TRUE
  )
  expect_identical(attr(parallel, "execution")$mode, "parallel")
  expect_identical(attr(parallel, "execution")$workers, 2L)
  expect_identical(attr(serial, "execution")$batches, 4L)
  expect_identical(
    attr(parallel, "reconciliation"),
    attr(serial, "reconciliation")
  )
  attr(serial, "execution") <- NULL
  attr(parallel, "execution") <- NULL
  expect_identical(parallel, serial)
})

test_that("serial batching splits work and preserves duplicates and order", {
  sizes <- integer()
  original <- search_with_agrep
  local_mocked_bindings(search_with_agrep = function(splist_unique, ...) {
    sizes <<- c(sizes, length(splist_unique))
    original(splist_unique, ...)
  })
  input <- c(
    "Falco sparverius",
    "Tinamus major",
    "Falko sparverius",
    NA,
    "",
    "Falco sparverius"
  )
  out <- search_avesperu(
    input,
    batch_size = 2,
    parallel = FALSE,
    return_details = TRUE
  )
  expect_identical(sizes, c(2L, 2L, 1L))
  expect_identical(out$name_submitted, input)
})

test_that("cluster creation failure returns sequential results and records fallback", {
  calls <- 0L
  local_mocked_bindings(create_search_cluster = function(n) {
    calls <<- calls + 1L
    stop("simulated creation failure")
  })
  expect_snapshot({
    out <- search_avesperu(
      c("Falko sparverius", "Tinamus major"),
      batch_size = 1,
      n_cores = 2,
      return_details = TRUE
    )
  })
  expect_identical(calls, 1L)
  expect_identical(out$accepted_name, c("Falco sparverius", "Tinamus major"))
  expect_identical(
    attr(out, "execution")$fallback,
    "simulated creation failure"
  )
  expect_identical(attr(out, "execution")$mode, "sequential")
})

test_that("cluster dispatch failure cleans up resources and falls back", {
  stopped <- 0L
  local_mocked_bindings(
    create_search_cluster = function(n) {
      structure(list(), class = "invalid_cluster")
    },
    stop_search_cluster = function(cl) {
      stopped <<- stopped + 1L
    }
  )
  expect_snapshot({
    out <- search_avesperu(
      c("Falco sparverius", "Tinamus major"),
      batch_size = 1,
      n_cores = 2,
      return_details = TRUE
    )
  })
  expect_identical(stopped, 1L)
  expect_identical(attr(out, "execution")$mode, "sequential")
})

test_that("core selection handles unknown detection and respects configured limits", {
  input <- c("Falco sparverius", "Tinamus major")
  local_mocked_bindings(
    detect_search_cores = function() NA_integer_,
    create_search_cluster = function(n) stop("unexpected cluster")
  )
  out <- search_avesperu(input, batch_size = 1, return_details = TRUE)
  expect_identical(attr(out, "execution")$workers, 1L)
  withr::local_options(mc.cores = 1L)
  expect_no_error(search_avesperu(input, batch_size = 1))
  withr::local_options(mc.cores = NA)
  expect_snapshot(error = TRUE, search_avesperu(input))
})

test_that("serialized workers keep current helpers private", {
  cl <- parallel::makeCluster(1L)
  withr::defer(parallel::stopCluster(cl))
  before <- parallel::clusterCall(cl, function() {
    ls(envir = globalenv(), all.names = TRUE)
  })
  worker <- make_search_worker()
  expect_identical(parent.env(environment(worker)), baseenv())
  db <- current_checklist()
  out <- parallel::parLapply(
    cl,
    list(1L),
    worker,
    names = "Falko sparverius",
    db = db,
    db_names = db$scientific_name,
    distance = 1
  )
  expect_identical(out[[1]]$accepted_name, "Falco sparverius")
  expect_identical(out[[1]]$match_type, "fuzzy")
  after <- parallel::clusterCall(cl, function() {
    ls(envir = globalenv(), all.names = TRUE)
  })
  expect_identical(after, before)
})
