public_forbidden_column_patterns <- c(
  "(^|_)nik($|_)",
  "(^|_)name($|_)",
  "(^|_)nama($|_)",
  "phone",
  "no_hp",
  "alamat",
  "address",
  "source_json",
  "free_text"
)

assert_public_columns <- function(data) {
  column_names <- tolower(names(data))
  forbidden <- unique(unlist(lapply(
    public_forbidden_column_patterns,
    function(pattern) grep(pattern, column_names, value = TRUE)
  )))

  if (length(forbidden) > 0L) {
    stop(
      "Public render blocked: forbidden columns detected: ",
      paste(forbidden, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data)
}

