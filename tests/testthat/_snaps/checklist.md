# invalid reference tables are rejected before publishing

    Code
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
        cat(kind, ": ", tryCatch({
          validate_checklist(db)
          "ACCEPTED"
        }, error = function(e) conditionMessage(e)), "\n", sep = "")
      }
    Output
      missing: Checklist column "family_name" contains missing or invalid values.
      swapped: Checklist scientific names must agree with genus and species epithet.
      duplicate: Checklist contains duplicate scientific names.
      code: Checklist contains unknown status codes.

