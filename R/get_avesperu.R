#' Search for Bird Species Data in the Birds of Peru Dataset
#'
#' @description
#' This function searches for bird species information in the dataset provided by
#' the \code{avesperu} package, given a list of species names. It supports approximate
#' (fuzzy) matching to handle typographical errors or minor variations in species
#' names using optimized edit-distance matching. The function is optimized for both
#' small and large lists through intelligent pre-filtering and optional parallel
#' processing.
#'
#' @param splist A character vector or factor containing the scientific names of
#'   bird species to search for. Names can include minor variations or typos.
#' @param max_distance Numeric. The maximum allowable distance for fuzzy matching.
#'   Can be either:
#'   \itemize{
#'     \item A proportion between 0 and 1 (e.g., 0.1 = 10\% of string length)
#'     \item An integer representing the maximum number of character differences
#'   }
#'   Default: 0.1.
#' @param return_details Logical. If \code{FALSE} (default), returns only a character
#'   vector of species status. If \code{TRUE}, returns a detailed data frame with
#'   complete reconciliation information including taxonomic data and matching distances.
#' @param batch_size Integer. Number of species to process per batch when handling
#'   large lists. Useful for memory management and progress tracking.
#'   Default: 100 species per batch.
#' @param parallel Logical. Should parallel processing be used for large lists?
#'   Automatically disabled for small lists. Requires the \code{parallel} package.
#'   Default: \code{TRUE}.
#' @param n_cores Integer or \code{NULL}. Number of CPU cores to use for parallel
#'   processing. Auto selection respects `mc.cores`, available batches and a
#'   limit of four workers. Unavailable core detection uses sequential execution.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Validates input and converts factors to character vectors
#'   \item Standardizes species names using \code{standardize_names()}
#'   \item Identifies and reports duplicate entries in the input list
#'   \item Uses intelligent pre-filtering to reduce search space:
#'     \itemize{
#'       \item Filters by string length (mathematically guaranteed to preserve matches)
#'     }
#'   \item Performs exact matching before fuzzy matching to avoid unnecessary work
#'   \item Calculates edit distances using \code{\link[stringdist:stringdist]{stringdist::stringdist()}}
#'   \item Selects the best match (minimum distance) for each query
#'   \item For large lists (>batch_size), processes in batches with optional parallelization
#' }
#'
#'
#' @return
#' The return value depends on the \code{return_details} parameter:
#'
#' \strong{If return_details = FALSE (default):}
#'
#' A character vector with the same length as \code{splist}, containing the
#' conservation/occurrence status for each species. \code{NA} values indicate
#' no unique match was found, or the input contains qualifiers or hybrid markers.
#'
#' \strong{If return_details = TRUE:}
#'
#' A data frame (tibble-compatible) with the following columns:
#' \describe{
#'   \item{name_submitted}{Character. The species name provided as input (standardized).}
#'   \item{accepted_name}{Character. The closest matching species name from the
#'     database, or \code{NA} if no match found within \code{max_distance}.}
#'   \item{order_name}{Character. The taxonomic order of the matched species.}
#'   \item{family_name}{Character. The taxonomic family of the matched species.}
#'   \item{english_name}{Character. Common name in English.}
#'   \item{spanish_name}{Character. Common name in Spanish.}
#'   \item{status}{Character. Conservation or occurrence status (e.g., "Endemic",
#'     "Resident", "Migrant", "Vagrant").}
#'   \item{dist}{Character. Edit distance between submitted and matched names.
#'     Lower values indicate better matches. \code{NA} if no match found.}
#' }
#'
#' The detailed result retains eight columns. Its `reconciliation` attribute is
#' a row-aligned data frame containing the original and standardized names,
#' qualifier/hybrid flags, match type, candidate count, candidate names and
#' review reasons. The `avesperu_result` data-frame subclass keeps this attribute
#' aligned when rows are selected using `[`.
#' Ambiguous matches have no accepted name or status; candidates are sorted.
#' Qualified and hybrid inputs can have a suggested match but always need review.
#' Attributes `execution` and `reference` record actual workers, batches,
#' fallback reason and the checklist identifier/date used.
#' Empty input returns a typed zero-row table or `character(0)`.
#' Proportions strictly between 0 and 1 use `ceiling(nchar(name) * distance)`;
#' 0 means exact only and values at least 1 must be whole edit counts.
#'
#' @section Warning:
#' For very large lists (>10,000 species) with parallel processing enabled,
#' ensure sufficient system memory is available. Each parallel worker maintains
#' a copy of the reference database (~5-10 MB).
#'
#' @seealso
#' \code{\link[stringdist:stringdist]{stringdist::stringdist}} for the underlying
#' edit-distance calculation
#'
#' @examples
#' # Basic usage - returns status vector
#' splist <- c("Falco sparverius", "Tinamus osgodi", "Crypturellus soui")
#' status <- search_avesperu(splist)
#' print(status)
#'
#' # Get detailed reconciliation information
#' details <- search_avesperu(splist, return_details = TRUE)
#' print(details)
#'
#' # Exact matching only (no fuzzy matching)
#' exact_results <- search_avesperu(splist, max_distance = 0)
#'
#' # Handle species with typos
#' typo_list <- c("Falco sparveruis", "Tinamus osgoodi", "Crypturellus sui")
#' corrected <- search_avesperu(typo_list, return_details = TRUE)
#'
#' # View submitted vs accepted names
#' print(corrected[, c("name_submitted", "accepted_name", "dist")])
#'
#' @export
search_avesperu <- function(
  splist,
  max_distance = 0.1,
  return_details = FALSE,
  batch_size = 100,
  parallel = TRUE,
  n_cores = NULL
) {
  if ((!is.character(splist) && !is.factor(splist)) || !is.null(dim(splist))) {
    cli::cli_abort("{.arg splist} must be a character vector or a factor.")
  }
  validate_search_options(
    max_distance,
    return_details,
    batch_size,
    parallel,
    n_cores
  )
  original <- as.character(splist)
  normalized <- normalize_name_records(original)
  unique_names <- unique(normalized$standardized_name)
  duplicates <- find_duplicates(normalized$standardized_name)
  if (length(duplicates)) {
    cli::cli_inform(
      "The following names are repeated in the {.arg splist}: {.val {duplicates}}"
    )
  }
  db <- current_checklist()
  if (length(unique_names) <= batch_size) {
    result <- search_with_agrep(
      unique_names,
      db,
      db$scientific_name,
      max_distance
    )
    execution <- list(
      mode = "sequential",
      workers = 1L,
      batches = as.integer(length(unique_names) > 0),
      fallback = NA_character_
    )
  } else {
    result <- search_with_agrep_batched(
      unique_names,
      db,
      db$scientific_name,
      max_distance,
      batch_size,
      parallel,
      n_cores
    )
    execution <- attr(result, "execution")
  }
  full <- result[
    match(normalized$standardized_name, result$name_submitted),
    ,
    drop = FALSE
  ]
  rownames(full) <- NULL
  audit <- cbind(
    normalized,
    full[, c("match_type", "candidate_count", "candidates"), drop = FALSE]
  )
  audit$review_reason <- ifelse(
    audit$has_hybrid,
    "hybrid",
    ifelse(audit$has_qualifier, "qualifier", "")
  )
  needs_match_review <- audit$match_type != "exact"
  audit$review_reason <- ifelse(
    needs_match_review,
    ifelse(
      nzchar(audit$review_reason),
      paste(audit$review_reason, audit$match_type, sep = ";"),
      audit$match_type
    ),
    audit$review_reason
  )
  audit$review_flag <- nzchar(audit$review_reason)
  result <- full[, names(create_empty_result("")), drop = FALSE]
  attr(result, "reconciliation") <- audit
  attr(result, "execution") <- execution
  attr(result, "reference") <- checklist_metadata(db)
  class(result) <- c("avesperu_result", "data.frame")
  if (return_details) {
    return(result)
  }
  status <- result$status
  status[audit$has_hybrid | audit$has_qualifier] <- NA_character_
  status
}

is_count <- function(x) {
  is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x >= 1 &&
    x <= .Machine$integer.max &&
    x == floor(x)
}

validate_search_options <- function(
  max_distance,
  return_details,
  batch_size,
  parallel,
  n_cores
) {
  for (arg in c("return_details", "parallel")) {
    value <- get(arg)
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      cli::cli_abort(
        "{.arg {arg}} must be a single logical value (TRUE or FALSE)."
      )
    }
  }
  if (
    !is.numeric(max_distance) ||
      length(max_distance) != 1L ||
      !is.finite(max_distance) ||
      max_distance < 0 ||
      max_distance > .Machine$integer.max
  ) {
    cli::cli_abort(
      "{.arg max_distance} must be a single non-negative numeric value that is finite and within integer range."
    )
  }
  if (max_distance >= 1 && max_distance != floor(max_distance)) {
    cli::cli_abort(
      "{.arg max_distance} must be an integer when it is at least 1."
    )
  }
  if (max_distance > 0.5 && max_distance < 1) {
    cli::cli_warn(
      "{.arg max_distance} > 0.5 may produce too many false matches."
    )
  }
  if (!is_count(batch_size)) {
    cli::cli_abort("{.arg batch_size} must be a positive integer.")
  }
  if (!is.null(n_cores) && !is_count(n_cores)) {
    cli::cli_abort("{.arg n_cores} must be NULL or a positive integer.")
  }
  if (parallel && is.null(n_cores) && !is_count(getOption("mc.cores", 2L))) {
    cli::cli_abort("{.code options(mc.cores)} must be a positive integer.")
  }
}

search_row <- function(name, db, indices = integer(), distance = NA_real_) {
  candidates <- sort(db$scientific_name[indices], method = "radix")
  row <- if (length(indices) == 1L) {
    create_match_result(name, db[indices, , drop = FALSE], distance)
  } else {
    create_empty_result(name)
  }
  if (length(indices)) {
    row$dist <- as.character(distance)
  }
  row$match_type <- if (!length(indices)) {
    "unmatched"
  } else if (length(indices) > 1L) {
    "ambiguous"
  } else if (distance == 0) {
    "exact"
  } else {
    "fuzzy"
  }
  row$candidate_count <- length(indices)
  row$candidates <- paste(candidates, collapse = "; ")
  row
}

search_with_agrep <- function(
  splist_unique,
  species_db,
  db_names,
  max_distance
) {
  if (!length(splist_unique)) {
    return(search_row("", species_db)[FALSE, , drop = FALSE])
  }
  db_lengths <- nchar(db_names)
  result <- lapply(splist_unique, function(name) {
    if (is.na(name) || !nzchar(name)) {
      return(search_row(name, species_db))
    }
    exact <- which(db_names == name)
    if (length(exact)) {
      return(search_row(name, species_db, exact, 0L))
    }
    limit <- if (max_distance > 0 && max_distance < 1) {
      ceiling(nchar(name) * max_distance)
    } else {
      max_distance
    }
    indices <- which(abs(db_lengths - nchar(name)) <= limit)
    if (!length(indices) || limit == 0) {
      return(search_row(name, species_db))
    }
    distances <- stringdist::stringdist(
      name,
      db_names[indices],
      method = "lv",
      nthread = 1L
    )
    best <- min(distances)
    if (!is.finite(best) || best > limit) {
      return(search_row(name, species_db))
    }
    search_row(name, species_db, indices[which(distances == best)], best)
  })
  out <- do.call(rbind, result)
  rownames(out) <- NULL
  out
}

# Wrappers allow testing failures without replacing bindings in parallel itself.
create_search_cluster <- function(n) parallel::makeCluster(n)
stop_search_cluster <- function(cl) parallel::stopCluster(cl)
detect_search_cores <- function() parallel::detectCores(logical = FALSE)

# Serialize the current helpers in a private environment, independent of any
# installed avesperu namespace and without modifying a worker's global state.
make_search_worker <- function() {
  worker_env <- new.env(parent = baseenv())
  helpers <- list(
    search_with_agrep = search_with_agrep,
    search_row = search_row,
    create_empty_result = create_empty_result,
    create_match_result = create_match_result
  )
  for (name in names(helpers)) {
    fun <- helpers[[name]]
    environment(fun) <- worker_env
    worker_env[[name]] <- fun
  }
  worker <- function(indices, names, db, db_names, distance) {
    search_with_agrep(names[indices], db, db_names, distance)
  }
  environment(worker) <- worker_env
  worker
}

search_with_agrep_batched <- function(
  splist_unique,
  species_db,
  db_names,
  max_distance,
  batch_size,
  parallel,
  n_cores
) {
  batches <- split(
    seq_along(splist_unique),
    ceiling(seq_along(splist_unique) / batch_size)
  )
  execution <- list(
    mode = "sequential",
    workers = 1L,
    batches = length(batches),
    fallback = NA_character_
  )
  process_batch <- function(indices) {
    search_with_agrep(
      splist_unique[indices],
      species_db,
      db_names,
      max_distance
    )
  }
  workers <- 1L
  if (parallel) {
    detected <- detect_search_cores()
    detected <- if (is_count(detected)) max(1L, detected - 1L) else 1L
    workers <- if (is.null(n_cores)) {
      min(detected, getOption("mc.cores", 2L), 4L, length(batches))
    } else {
      min(n_cores, length(batches))
    }
  }
  batch_results <- NULL
  if (workers > 1L) {
    cl <- NULL
    on.exit(if (!is.null(cl)) stop_search_cluster(cl), add = TRUE)
    batch_results <- tryCatch(
      {
        cl <- create_search_cluster(workers)
        worker <- make_search_worker()
        parallel::parLapply(
          cl,
          batches,
          worker,
          names = splist_unique,
          db = species_db,
          db_names = db_names,
          distance = max_distance
        )
      },
      error = function(e) {
        execution$fallback <<- conditionMessage(e)
        cli::cli_warn(
          "Parallel processing failed. Falling back to sequential processing: {conditionMessage(e)}"
        )
        NULL
      }
    )
    if (!is.null(batch_results)) {
      execution$mode <- "parallel"
      execution$workers <- as.integer(workers)
    }
  }
  if (is.null(batch_results)) {
    batch_results <- lapply(batches, process_batch)
  }
  out <- if (length(batch_results)) {
    do.call(rbind, batch_results)
  } else {
    search_with_agrep(character(), species_db, db_names, max_distance)
  }
  rownames(out) <- NULL
  attr(out, "execution") <- execution
  out
}

create_empty_result <- function(sp_name) {
  data.frame(
    name_submitted = sp_name,
    accepted_name = NA_character_,
    order_name = NA_character_,
    family_name = NA_character_,
    english_name = NA_character_,
    spanish_name = NA_character_,
    status = NA_character_,
    dist = NA_character_,
    stringsAsFactors = FALSE
  )
}


#' Create Result Row for Matched Species
#'
#' @description
#' Internal helper function that creates a standardized data frame row for species
#' that have been successfully matched in the reference database.
#'
#' @param sp_name Character. The submitted species name (standardized).
#' @param matched_row Data frame row (single row) from the reference database.
#' @param distance Numeric. The edit distance between submitted and matched names.
#'
#' @return A single-row data frame with complete species information.
#'
#' @keywords internal
#' @noRd
create_match_result <- function(sp_name, matched_row, distance) {
  data.frame(
    name_submitted = sp_name,
    accepted_name = matched_row$scientific_name,
    order_name = matched_row$order_name,
    family_name = matched_row$family_name,
    english_name = matched_row$english_name,
    spanish_name = matched_row$spanish_name,
    status = matched_row$status,
    dist = as.character(distance),
    stringsAsFactors = FALSE
  )
}
