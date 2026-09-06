monitoring_data_source <- function() {
  tolower(env_or_default("MONITORING_DATA_SOURCE", "disabled"))
}

validate_bigquery_identifier <- function(value, label) {
  if (!grepl("^[A-Za-z0-9_-]+$", value)) {
    stop("Invalid ", label, ": ", value, call. = FALSE)
  }
  value
}

read_public_monitoring_view <- function(context, view_name) {
  mode <- monitoring_data_source()

  if (mode %in% c("", "disabled", "off", "none")) {
    return(NULL)
  }
  if (!identical(mode, "bigquery")) {
    stop(
      "MONITORING_DATA_SOURCE must be 'disabled' or 'bigquery'.",
      call. = FALSE
    )
  }
  if (!requireNamespace("bigrquery", quietly = TRUE)) {
    stop(
      "The bigrquery package is required when BigQuery rendering is enabled.",
      call. = FALSE
    )
  }

  project <- validate_bigquery_identifier(context$gcp_project, "GCP project")
  dataset <- validate_bigquery_identifier(
    context$monitoring_dataset,
    "monitoring dataset"
  )
  view <- validate_bigquery_identifier(view_name, "monitoring view")

  sql <- sprintf("SELECT * FROM `%s.%s.%s`", project, dataset, view)
  result_table <- bigrquery::bq_project_query(
    project,
    sql,
    location = context$bigquery_location,
    use_legacy_sql = FALSE,
    quiet = TRUE
  )
  result <- as.data.frame(bigrquery::bq_table_download(
    result_table,
    api = "json",
    quiet = TRUE
  ))

  assert_public_columns(result)
  result
}

render_monitoring_table <- function(data, empty_message) {
  if (is.null(data)) {
    cat("::: {.status-banner}\n")
    cat("**Data connection pending:** ", empty_message, "\n", sep = "")
    cat(":::\n")
    return(invisible(NULL))
  }

  assert_public_columns(data)
  print(knitr::kable(data, format = "pipe", row.names = FALSE))
  invisible(data)
}
