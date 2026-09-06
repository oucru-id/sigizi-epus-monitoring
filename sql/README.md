# Monitoring SQL

This directory contains monitoring-specific curated view definitions and
their contract checks. The first implemented contract is SIGIZI:

- `views/10_sigizi_monitoring.sql`
- `contract_checks/10_sigizi_monitoring_checks.sql`

Before adding views, verify the live schemas and grains of the upstream
`spheres-lombok-barat.kohort_bumil_v3` objects. Do not treat repository SQL as
proof of the currently deployed BigQuery schema.

Planned cross-source contracts:

- `v_monitor_source_daily`
- `v_monitor_anc_daily`
- `v_monitor_inc_daily`
- `v_monitor_pnc_daily`
- `v_monitor_pregnancy_service_coverage`
- `v_monitor_data_quality_daily`
