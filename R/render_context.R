env_or_default <- function(name, default) {
  value <- Sys.getenv(name, unset = "")
  if (identical(value, "")) default else value
}

monitoring_context <- function() {
  list(
    gcp_project = env_or_default("GCP_PROJECT", "spheres-lombok-barat"),
    upstream_dataset = env_or_default(
      "BIRTH_OUTCOME_DATASET",
      "kohort_bumil_v3"
    ),
    monitoring_dataset = env_or_default(
      "MONITORING_DATASET",
      "sigizi_epus_monitoring"
    ),
    bigquery_location = env_or_default(
      "BIGQUERY_LOCATION",
      "asia-southeast2"
    ),
    publication_mode = env_or_default(
      "PUBLICATION_MODE",
      "aggregate_only"
    ),
    rendered_at = format(
      Sys.time(),
      tz = "Asia/Makassar",
      format = "%Y-%m-%d %H:%M %Z"
    )
  )
}

