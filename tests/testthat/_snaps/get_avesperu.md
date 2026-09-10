# invalid scalar options fail before matching

    Code
      for (arg in names(invalid)) {
        for (value in invalid[[arg]]) {
          args <- c(list(splist = "Falco sparverius"), setNames(list(value), arg))
          cat(arg, ": ", tryCatch({
            do.call(search_avesperu, args)
            "ACCEPTED"
          }, error = function(e) conditionMessage(e)), "\n", sep = "")
        }
      }
    Output
      max_distance: `max_distance` must be a single non-negative numeric value that is finite and within integer range.
      max_distance: `max_distance` must be a single non-negative numeric value that is finite and within integer range.
      max_distance: `max_distance` must be a single non-negative numeric value that is finite and within integer range.
      max_distance: `max_distance` must be a single non-negative numeric value that is finite and within integer range.
      max_distance: `max_distance` must be an integer when it is at least 1.
      max_distance: `max_distance` must be a single non-negative numeric value that is finite and within integer range.
      batch_size: `batch_size` must be a positive integer.
      batch_size: `batch_size` must be a positive integer.
      batch_size: `batch_size` must be a positive integer.
      batch_size: `batch_size` must be a positive integer.
      n_cores: `n_cores` must be NULL or a positive integer.
      n_cores: `n_cores` must be NULL or a positive integer.
      n_cores: `n_cores` must be NULL or a positive integer.
      n_cores: `n_cores` must be NULL or a positive integer.
      return_details: `return_details` must be a single logical value (TRUE or FALSE).
      return_details: `return_details` must be a single logical value (TRUE or FALSE).
      return_details: `return_details` must be a single logical value (TRUE or FALSE).
      parallel: `parallel` must be a single logical value (TRUE or FALSE).

