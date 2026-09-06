source("R/render_context.R")
source("R/privacy.R")
source("R/monitoring_data.R")

old_mode <- Sys.getenv("MONITORING_DATA_SOURCE", unset = NA_character_)
on.exit({
  if (is.na(old_mode)) {
    Sys.unsetenv("MONITORING_DATA_SOURCE")
  } else {
    Sys.setenv(MONITORING_DATA_SOURCE = old_mode)
  }
}, add = TRUE)

Sys.setenv(MONITORING_DATA_SOURCE = "disabled")
context <- monitoring_context()

stopifnot(is.null(read_public_monitoring_view(
  context,
  "v_sigizi_source_monitoring"
)))

safe_data <- data.frame(
  monitoring_stage = c("ANC", "INC", "PNC"),
  aggregate_count = c(100L, 80L, NA_integer_)
)
stopifnot(identical(assert_public_columns(safe_data), safe_data))

unsafe_error <- tryCatch(
  {
    assert_public_columns(data.frame(nama = "not-public"))
    NULL
  },
  error = identity
)
stopifnot(inherits(unsafe_error, "error"))

identifier_error <- tryCatch(
  {
    validate_bigquery_identifier("bad.identifier", "test identifier")
    NULL
  },
  error = identity
)
stopifnot(inherits(identifier_error, "error"))

cat("SIGIZI monitoring R checks passed.\n")
