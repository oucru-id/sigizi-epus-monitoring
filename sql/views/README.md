# Aggregate monitoring views

`10_sigizi_monitoring.sql` defines the first aggregate-safe source-system
contract. It was mapped to the reviewed upstream repository schema, but still
requires live BigQuery validation before operational publication.

Views must expose aggregate-safe fields for the static website and keep source,
visit, pregnancy, delivery, and baby grains explicit.
