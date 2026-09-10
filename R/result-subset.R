#' @export
#' @noRd
`[.avesperu_result` <- function(x, i, j, drop = FALSE) {
  audit <- attr(x, "reconciliation")
  argument_count <- nargs()
  if (!missing(drop)) {
    argument_count <- argument_count - 1L
  }
  dimensional <- argument_count >= 3L
  class(x) <- "data.frame"
  out <- if (!dimensional) {
    if (missing(i)) x[] else x[i]
  } else if (missing(i) && missing(j)) {
    x[,, drop = drop]
  } else if (missing(i)) {
    x[, j, drop = drop]
  } else if (missing(j)) {
    x[i, , drop = drop]
  } else {
    x[i, j, drop = drop]
  }
  if (is.data.frame(out)) {
    if (dimensional && !missing(i)) {
      audit <- audit[i, , drop = FALSE]
    }
    attr(audit, "row.names") <- attr(out, "row.names")
    attr(out, "reconciliation") <- audit
    class(out) <- c("avesperu_result", "data.frame")
  }
  out
}
