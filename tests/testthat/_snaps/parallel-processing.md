# cluster creation failure returns sequential results and records fallback

    Code
      out <- search_avesperu(c("Falko sparverius", "Tinamus major"), batch_size = 1,
      n_cores = 2, return_details = TRUE)
    Condition
      Warning:
      Parallel processing failed. Falling back to sequential processing: simulated creation failure

# cluster dispatch failure cleans up resources and falls back

    Code
      out <- search_avesperu(c("Falco sparverius", "Tinamus major"), batch_size = 1,
      n_cores = 2, return_details = TRUE)
    Condition
      Warning:
      Parallel processing failed. Falling back to sequential processing: not a valid cluster

# core selection handles unknown detection and respects configured limits

    Code
      search_avesperu(input)
    Condition
      Error in `validate_search_options()`:
      ! `options(mc.cores)` must be a positive integer.

