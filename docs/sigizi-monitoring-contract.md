# SIGIZI monitoring contract

## Upstream authority

The `birth-outcome` pipeline remains authoritative for all row-level work:

1. Standardize the five clinical cleaning views.
2. Apply pregnancy-specific matches from `vs_sigizi_bumil_hapus`.
3. Publish retained records to `t_sigizi_source_records` and excluded records
   to the restricted audit table.
4. Correct geography in the retained source table.
5. Build `t_sigizi_pregnancy_episode_v3_3`.

The monitoring repository must not union the deletion registry with clinical
sources or recreate patient matching in R.

## Source-to-stage map

| Stage | Included retained source values | Canonical measure available now |
|---|---|---|
| ANC | `DAFTAR_IBU_HAMIL`, `ANC` | Pregnancy source evidence and pregnancy with explicit ANC date |
| INC | `KOHORT_IBU`, `KOHORT_NIFAS` | Pregnancy source evidence and pregnancy with delivery evidence |
| PNC | `KOHORT_NIFAS` | Source availability only |
| Context | `DAFTAR_IBU` | Source volume and pregnancy context only |
| Exclusion | `vs_sigizi_bumil_hapus` | Aggregate gate reconciliation only; never clinical evidence |

PNC visit counts and KF1-KF4 coverage are blocked until the upstream pipeline
provides a curated visit-grain adapter with explicit service dates and stage
definitions.

## Public views

`sql/views/10_sigizi_monitoring.sql` defines:

- `v_sigizi_source_monitoring`: one row per configured clinical source.
- `v_sigizi_stage_monitoring`: one row per ANC, INC, or PNC monitoring stage.
- `v_sigizi_deletion_monitoring`: one aggregate row for the latest deletion
  gate build.

All non-zero counts below five are returned as null and flagged. The views do
not expose names, identifiers, telephone numbers, addresses, free text, source
JSON, row-level IDs, or row-level dates.

## Deployment and validation

Run in `asia-southeast2`, after the complete upstream SIGIZI refresh:

1. `sql/views/10_sigizi_monitoring.sql`
2. `sql/contract_checks/10_sigizi_monitoring_checks.sql`

These files were derived from the supplied matching guide and repository SQL.
They still require live BigQuery schema validation and execution in the
approved environment before the website can display operational figures.

After deployment, enable a controlled render with:

```text
MONITORING_DATA_SOURCE=bigquery
```

The render identity needs BigQuery read/query access to the three aggregate
views. No credential or row-level extract may be committed to GitHub.
