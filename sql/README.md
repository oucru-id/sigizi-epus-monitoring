# Monitoring SQL

This directory will contain monitoring-specific curated view definitions and
their contract checks.

Before adding views, verify the live schemas and grains of the upstream
`spheres-lombok-barat.kohort_bumil_v3` objects. Do not treat repository SQL as
proof of the currently deployed BigQuery schema.

Planned contracts:

- `v_monitor_source_daily`
- `v_monitor_anc_daily`
- `v_monitor_inc_daily`
- `v_monitor_pnc_daily`
- `v_monitor_pregnancy_service_coverage`
- `v_monitor_data_quality_daily`

