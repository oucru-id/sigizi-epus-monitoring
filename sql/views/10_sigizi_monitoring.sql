-- Aggregate-only SIGIZI monitoring views for the public Quarto site.
--
-- Upstream prerequisite order in the birth-outcome pipeline:
--   03_sigizi_source.sql (including the deletion gate)
--   03a_sigizi_geography.sql
--   10_sigizi_episodes.sql
--
-- These views do not recreate source cleaning, deletion matching, geography
-- correction, deduplication, or pregnancy construction.

CREATE SCHEMA IF NOT EXISTS
  `spheres-lombok-barat.sigizi_epus_monitoring`
OPTIONS(location = 'asia-southeast2');

CREATE OR REPLACE VIEW
  `spheres-lombok-barat.sigizi_epus_monitoring.v_sigizi_source_monitoring`
AS
WITH source_contract AS (
  SELECT *
  FROM UNNEST([
    STRUCT(
      'DAFTAR_IBU_HAMIL' AS source_table,
      'Ibu hamil' AS source_label,
      'ANC' AS monitoring_domain,
      'Pregnancy registration/evidence; not an ANC encounter by itself'
        AS monitoring_role,
      TRUE AS supports_anc,
      FALSE AS supports_inc,
      FALSE AS supports_pnc
    ),
    STRUCT(
      'ANC' AS source_table,
      'Pemeriksaan ANC' AS source_label,
      'ANC' AS monitoring_domain,
      'Explicit ANC examination evidence' AS monitoring_role,
      TRUE AS supports_anc,
      FALSE AS supports_inc,
      FALSE AS supports_pnc
    ),
    STRUCT(
      'KOHORT_IBU' AS source_table,
      'Kohort ibu' AS source_label,
      'INC' AS monitoring_domain,
      'INC and delivery evidence' AS monitoring_role,
      FALSE AS supports_anc,
      TRUE AS supports_inc,
      FALSE AS supports_pnc
    ),
    STRUCT(
      'KOHORT_NIFAS' AS source_table,
      'Kohort nifas' AS source_label,
      'INC / PNC' AS monitoring_domain,
      'INC evidence; PNC visits await a curated visit-level adapter'
        AS monitoring_role,
      FALSE AS supports_anc,
      TRUE AS supports_inc,
      TRUE AS supports_pnc
    ),
    STRUCT(
      'DAFTAR_IBU' AS source_table,
      'Daftar ibu' AS source_label,
      'CONTEXT' AS monitoring_domain,
      'Pregnancy registry and source-presence context' AS monitoring_role,
      FALSE AS supports_anc,
      FALSE AS supports_inc,
      FALSE AS supports_pnc
    )
  ])
),
active AS (
  SELECT
    source_table,
    COUNT(*) AS active_record_count,
    COUNTIF(pregnancy_anchor_date IS NOT NULL)
      AS records_with_pregnancy_timing,
    COUNTIF(
      CASE source_table
        WHEN 'ANC' THEN anc_date
        WHEN 'KOHORT_IBU' THEN delivery_date
        WHEN 'KOHORT_NIFAS' THEN delivery_date
        ELSE NULL
      END IS NOT NULL
    ) AS records_with_explicit_service_date,
    COUNTIF(puskesmas_norm IS NOT NULL) AS records_with_location,
    COUNTIF(flag_nik_valid) AS records_with_valid_primary_identifier,
    MIN(
      CASE source_table
        WHEN 'ANC' THEN anc_date
        WHEN 'DAFTAR_IBU_HAMIL' THEN pregnancy_anchor_date
        WHEN 'KOHORT_IBU' THEN delivery_date
        WHEN 'KOHORT_NIFAS' THEN delivery_date
        WHEN 'DAFTAR_IBU' THEN pregnancy_anchor_date
      END
    ) AS earliest_evidence_date,
    MAX(
      CASE source_table
        WHEN 'ANC' THEN anc_date
        WHEN 'DAFTAR_IBU_HAMIL' THEN pregnancy_anchor_date
        WHEN 'KOHORT_IBU' THEN delivery_date
        WHEN 'KOHORT_NIFAS' THEN delivery_date
        WHEN 'DAFTAR_IBU' THEN pregnancy_anchor_date
      END
    ) AS latest_evidence_date
  FROM `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_source_records`
  GROUP BY source_table
),
excluded AS (
  SELECT
    source_table,
    COUNT(*) AS excluded_record_count
  FROM
    `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_deletion_exclusion_audit`
  GROUP BY source_table
),
combined AS (
  SELECT
    c.*,
    COALESCE(a.active_record_count, 0) AS active_record_count,
    COALESCE(e.excluded_record_count, 0) AS excluded_record_count,
    COALESCE(a.active_record_count, 0)
      + COALESCE(e.excluded_record_count, 0) AS record_count_before_exclusion,
    COALESCE(a.records_with_pregnancy_timing, 0)
      AS records_with_pregnancy_timing,
    COALESCE(a.records_with_explicit_service_date, 0)
      AS records_with_explicit_service_date,
    COALESCE(a.records_with_location, 0) AS records_with_location,
    COALESCE(a.records_with_valid_primary_identifier, 0)
      AS records_with_valid_primary_identifier,
    a.earliest_evidence_date,
    a.latest_evidence_date
  FROM source_contract AS c
  LEFT JOIN active AS a USING (source_table)
  LEFT JOIN excluded AS e USING (source_table)
)
SELECT
  source_table,
  source_label,
  monitoring_domain,
  monitoring_role,
  supports_anc,
  supports_inc,
  supports_pnc,
  IF(active_record_count BETWEEN 1 AND 4, NULL, active_record_count)
    AS active_record_count,
  IF(excluded_record_count BETWEEN 1 AND 4, NULL, excluded_record_count)
    AS excluded_record_count,
  IF(
    record_count_before_exclusion BETWEEN 1 AND 4,
    NULL,
    record_count_before_exclusion
  ) AS record_count_before_exclusion,
  IF(
    records_with_pregnancy_timing BETWEEN 1 AND 4,
    NULL,
    records_with_pregnancy_timing
  ) AS records_with_pregnancy_timing,
  IF(
    records_with_explicit_service_date BETWEEN 1 AND 4,
    NULL,
    records_with_explicit_service_date
  ) AS records_with_explicit_service_date,
  IF(records_with_location BETWEEN 1 AND 4, NULL, records_with_location)
    AS records_with_location,
  IF(
    records_with_valid_primary_identifier BETWEEN 1 AND 4,
    NULL,
    records_with_valid_primary_identifier
  ) AS records_with_valid_primary_identifier,
  earliest_evidence_date,
  latest_evidence_date,
  active_record_count BETWEEN 1 AND 4
    OR excluded_record_count BETWEEN 1 AND 4
    OR record_count_before_exclusion BETWEEN 1 AND 4
    OR records_with_pregnancy_timing BETWEEN 1 AND 4
    OR records_with_explicit_service_date BETWEEN 1 AND 4
    OR records_with_location BETWEEN 1 AND 4
    OR records_with_valid_primary_identifier BETWEEN 1 AND 4
    AS has_suppressed_small_count
FROM combined
ORDER BY
  CASE source_table
    WHEN 'DAFTAR_IBU_HAMIL' THEN 1
    WHEN 'ANC' THEN 2
    WHEN 'KOHORT_IBU' THEN 3
    WHEN 'KOHORT_NIFAS' THEN 4
    WHEN 'DAFTAR_IBU' THEN 5
    ELSE 99
  END;

CREATE OR REPLACE VIEW
  `spheres-lombok-barat.sigizi_epus_monitoring.v_sigizi_stage_monitoring`
AS
WITH source_counts AS (
  SELECT
    COUNTIF(source_table IN ('DAFTAR_IBU_HAMIL', 'ANC'))
      AS anc_source_records,
    COUNTIF(source_table IN ('KOHORT_IBU', 'KOHORT_NIFAS'))
      AS inc_source_records,
    COUNTIF(source_table = 'KOHORT_NIFAS') AS pnc_source_records
  FROM `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_source_records`
),
episode_counts AS (
  SELECT
    COUNTIF(EXISTS(
      SELECT 1 FROM UNNEST(sigizi_source_tables) AS source_name
      WHERE source_name IN ('DAFTAR_IBU_HAMIL', 'ANC')
    )) AS anc_pregnancies_with_source_evidence,
    COUNTIF(first_anc_date IS NOT NULL)
      AS anc_pregnancies_with_explicit_visit,
    COUNTIF(EXISTS(
      SELECT 1 FROM UNNEST(sigizi_source_tables) AS source_name
      WHERE source_name IN ('KOHORT_IBU', 'KOHORT_NIFAS')
    )) AS inc_pregnancies_with_source_evidence,
    COUNTIF(
      delivery_sigizi IS NOT NULL
      AND delivery_sigizi_source_table IN ('KOHORT_IBU', 'KOHORT_NIFAS')
    ) AS inc_pregnancies_with_delivery_evidence,
    COUNTIF(EXISTS(
      SELECT 1 FROM UNNEST(sigizi_source_tables) AS source_name
      WHERE source_name = 'KOHORT_NIFAS'
    )) AS pnc_pregnancies_with_source_evidence
  FROM
    `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_pregnancy_episode_v3_3`
),
stage_rows AS (
  SELECT
    'ANC' AS monitoring_stage,
    anc_source_records AS source_record_count,
    anc_pregnancies_with_source_evidence AS pregnancy_evidence_count,
    anc_pregnancies_with_explicit_visit AS explicit_event_pregnancy_count,
    'SOURCE_AND_PREGNANCY_READY' AS measure_status,
    'DAFTAR_IBU_HAMIL + ANC retained records; canonical SIGIZI pregnancy episodes'
      AS denominator_definition
  FROM source_counts CROSS JOIN episode_counts

  UNION ALL

  SELECT
    'INC',
    inc_source_records,
    inc_pregnancies_with_source_evidence,
    inc_pregnancies_with_delivery_evidence,
    'SOURCE_AND_PREGNANCY_READY',
    'KOHORT_IBU + KOHORT_NIFAS retained records; pregnancies with delivery evidence'
  FROM source_counts CROSS JOIN episode_counts

  UNION ALL

  SELECT
    'PNC',
    pnc_source_records,
    pnc_pregnancies_with_source_evidence,
    CAST(NULL AS INT64),
    'PNC_VISIT_ADAPTER_REQUIRED',
    'KOHORT_NIFAS source presence only; KF1-KF4 is not yet defined'
  FROM source_counts CROSS JOIN episode_counts
)
SELECT
  monitoring_stage,
  IF(source_record_count BETWEEN 1 AND 4, NULL, source_record_count)
    AS source_record_count,
  IF(pregnancy_evidence_count BETWEEN 1 AND 4, NULL, pregnancy_evidence_count)
    AS pregnancy_evidence_count,
  IF(
    explicit_event_pregnancy_count BETWEEN 1 AND 4,
    NULL,
    explicit_event_pregnancy_count
  ) AS explicit_event_pregnancy_count,
  measure_status,
  denominator_definition,
  source_record_count BETWEEN 1 AND 4
    OR pregnancy_evidence_count BETWEEN 1 AND 4
    OR explicit_event_pregnancy_count BETWEEN 1 AND 4
    AS has_suppressed_small_count
FROM stage_rows
ORDER BY CASE monitoring_stage WHEN 'ANC' THEN 1 WHEN 'INC' THEN 2 ELSE 3 END;

CREATE OR REPLACE VIEW
  `spheres-lombok-barat.sigizi_epus_monitoring.v_sigizi_deletion_monitoring`
AS
SELECT
  exclusion_refreshed_at,
  exclusion_rule_version,
  IF(registry_rows BETWEEN 1 AND 4, NULL, registry_rows)
    AS deletion_registry_count,
  IF(source_rows_before_exclusion BETWEEN 1 AND 4, NULL,
    source_rows_before_exclusion) AS source_rows_before_exclusion,
  IF(excluded_source_rows BETWEEN 1 AND 4, NULL, excluded_source_rows)
    AS excluded_source_record_count,
  IF(active_source_rows BETWEEN 1 AND 4, NULL, active_source_rows)
    AS active_source_record_count,
  IF(source_rows_without_anchor BETWEEN 1 AND 4, NULL,
    source_rows_without_anchor) AS source_records_without_pregnancy_anchor,
  registry_rows BETWEEN 1 AND 4
    OR source_rows_before_exclusion BETWEEN 1 AND 4
    OR excluded_source_rows BETWEEN 1 AND 4
    OR active_source_rows BETWEEN 1 AND 4
    OR source_rows_without_anchor BETWEEN 1 AND 4
    AS has_suppressed_small_count
FROM
  `spheres-lombok-barat.kohort_bumil_v3.t_sigizi_deletion_exclusion_summary`;
