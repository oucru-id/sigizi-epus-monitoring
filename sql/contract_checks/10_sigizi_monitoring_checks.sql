-- Run after sql/views/10_sigizi_monitoring.sql.

ASSERT NOT EXISTS (
  SELECT 1
  FROM `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_source_records`
  WHERE source_table NOT IN (
    'ANC', 'DAFTAR_IBU', 'DAFTAR_IBU_HAMIL', 'KOHORT_IBU', 'KOHORT_NIFAS'
  )
) AS 'Unexpected source_table in retained SIGIZI clinical records';

ASSERT NOT EXISTS (
  SELECT 1
  FROM `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_source_records`
  WHERE source_table = 'BUMIL_HAPUS'
) AS 'Deletion registry leaked into the retained clinical source table';

ASSERT (
  SELECT source_rows_before_exclusion = excluded_source_rows + active_source_rows
  FROM `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_deletion_exclusion_summary`
) AS 'Deletion summary does not reconcile';

ASSERT (
  SELECT COUNT(*) = 3
  FROM `spheres-lombok-barat.sigizi_epus_monitoring.v_sigizi_stage_monitoring`
) AS 'SIGIZI stage view must contain ANC, INC, and PNC rows';

ASSERT NOT EXISTS (
  SELECT 1
  FROM `spheres-lombok-barat.sigizi_epus_monitoring.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name IN (
    'v_sigizi_source_monitoring',
    'v_sigizi_stage_monitoring',
    'v_sigizi_deletion_monitoring'
  )
  AND REGEXP_CONTAINS(
    column_name,
    r'(?i)(^|_)(nik|nama|name|phone|no_hp|alamat|address)($|_)|source_json|free_text'
  )
) AS 'A public monitoring view exposes a prohibited identifier-like column';
