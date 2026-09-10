current_checklist <- function() avesperu::aves_peru_2026_v1

reconcile_checklist_parts <- function(db) {
  # scientific_name is the resolver's canonical key, not a taxonomic opinion.
  expected <- paste(db$genus, db$species_epithet)
  rows <- which(!is.na(db$scientific_name) & db$scientific_name != expected)
  if (length(rows)) {
    corrections <- db[
      rows,
      c("scientific_name", "genus", "species_epithet"),
      drop = FALSE
    ]
    names(corrections)[2:3] <- c("source_genus", "source_species_epithet")
    parts <- strsplit(db$scientific_name[rows], " ", fixed = TRUE)
    if (any(lengths(parts) != 2L)) {
      cli::cli_abort(
        "Cannot derive components from a non-binomial reference name."
      )
    }
    db$genus[rows] <- vapply(parts, `[`, character(1), 1L)
    db$species_epithet[rows] <- vapply(parts, `[`, character(1), 2L)
    corrections$derived_genus <- db$genus[rows]
    corrections$derived_species_epithet <- db$species_epithet[rows]
    attr(db, "component_corrections") <- corrections
  }
  db
}

checklist_metadata <- function(db = current_checklist()) {
  fingerprint_file <- tempfile("avesperu-reference-")
  on.exit(unlink(fingerprint_file), add = TRUE)
  payload <- lapply(db, identity)
  saveRDS(payload, fingerprint_file, version = 2, compress = FALSE)
  list(
    id = "aves_peru_2026_v1",
    content_md5 = unname(tools::md5sum(fingerprint_file)),
    version_date = attr(db, "version_date"),
    source_url = attr(db, "source_url"),
    package_version = as.character(utils::packageVersion("avesperu"))
  )
}

validate_checklist <- function(db) {
  required <- c(
    "order_name",
    "family_name",
    "genus",
    "species_epithet",
    "scientific_name",
    "spanish_name",
    "english_name",
    "status_code",
    "status"
  )
  if (
    !is.data.frame(db) ||
      !all(required %in% names(db)) ||
      !nrow(db)
  ) {
    cli::cli_abort(
      "Checklist must be a nonempty table with all required columns."
    )
  }
  for (column in required) {
    if (
      !is.character(db[[column]]) ||
        anyNA(db[[column]]) ||
        any(!nzchar(trimws(db[[column]])))
    ) {
      cli::cli_abort(
        "Checklist column {.val {column}} contains missing or invalid values."
      )
    }
  }
  if (anyDuplicated(db$scientific_name)) {
    cli::cli_abort("Checklist contains duplicate scientific names.")
  }
  if (
    any(db$scientific_name != paste(db$genus, db$species_epithet)) ||
      any(
        db$scientific_name !=
          normalize_name_records(
            db$scientific_name,
            warn = FALSE
          )$standardized_name
      )
  ) {
    cli::cli_abort(
      "Checklist scientific names must agree with genus and species epithet."
    )
  }
  if (any(!db$status_code %in% c("E", "NB", "V", "IN", "U", "EX", "X"))) {
    cli::cli_abort("Checklist contains unknown status codes.")
  }
  invisible(db)
}

read_checklist_source <- function(path) {
  # Column names identify the schema; row positions only locate the header.
  header <- c(
    "orden",
    "familia",
    "genero",
    "especie",
    "nombre cientifico",
    "nombre peruano",
    "nombre en ingles",
    "estatus"
  )
  raw <- as.data.frame(readxl::read_excel(
    path,
    col_names = FALSE,
    range = readxl::cell_limits(c(1, 1), c(NA, NA)),
    col_types = "text"
  ))
  normalize_header <- function(x) {
    x <- chartr("\u00e1\u00e9\u00ed\u00f3\u00fa", "aeiou", tolower(trimws(x)))
    gsub("[[:space:]]+", " ", x)
  }
  hits <- which(vapply(
    seq_len(nrow(raw)),
    function(i) {
      all(header %in% normalize_header(unlist(raw[i, ], use.names = FALSE)))
    },
    logical(1)
  ))
  if (length(hits) != 1L) {
    cli::cli_abort("Could not identify one unique checklist header.")
  }
  names_in_row <- normalize_header(unlist(raw[hits, ], use.names = FALSE))
  if (anyDuplicated(names_in_row[!is.na(names_in_row)])) {
    cli::cli_abort("Duplicate checklist headers.")
  }
  out <- raw[
    seq_len(nrow(raw)) > hits,
    match(header, names_in_row),
    drop = FALSE
  ]
  names(out) <- c(
    "order_name",
    "family_name",
    "genus",
    "species_epithet",
    "scientific_name",
    "spanish_name",
    "english_name",
    "status"
  )
  out[] <- lapply(out, trimws)
  # Only entirely empty rows are discarded. Partial rows must fail validation.
  out <- out[rowSums(!is.na(out) & out != "", na.rm = TRUE) > 0, , drop = FALSE]
  out
}
