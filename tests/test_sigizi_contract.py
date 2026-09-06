from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
VIEW_SQL = (ROOT / "sql/views/10_sigizi_monitoring.sql").read_text(
    encoding="utf-8"
)
CHECK_SQL = (ROOT / "sql/contract_checks/10_sigizi_monitoring_checks.sql").read_text(
    encoding="utf-8"
)


class SigiziContractTest(unittest.TestCase):
    def test_all_five_clinical_sources_are_configured(self):
        for source in (
            "ANC",
            "DAFTAR_IBU",
            "DAFTAR_IBU_HAMIL",
            "KOHORT_IBU",
            "KOHORT_NIFAS",
        ):
            self.assertIn(f"'{source}' AS source_table", VIEW_SQL)

    def test_deletion_registry_is_not_a_configured_clinical_source(self):
        self.assertNotIn("'BUMIL_HAPUS' AS source_table", VIEW_SQL)
        self.assertIn("source_table = 'BUMIL_HAPUS'", CHECK_SQL)

    def test_stage_contract_matches_requested_source_roles(self):
        compact = re.sub(r"\s+", " ", VIEW_SQL)
        self.assertIn(
            "source_table IN ('DAFTAR_IBU_HAMIL', 'ANC')", compact
        )
        self.assertIn(
            "source_table IN ('KOHORT_IBU', 'KOHORT_NIFAS')", compact
        )
        self.assertIn("PNC_VISIT_ADAPTER_REQUIRED", VIEW_SQL)

    def test_public_small_cell_suppression_is_present(self):
        self.assertGreaterEqual(VIEW_SQL.count("BETWEEN 1 AND 4"), 10)
        self.assertIn("has_suppressed_small_count", VIEW_SQL)

    def test_public_view_contract_blocks_identifier_columns(self):
        for prohibited in (
            "nik|nama|name|phone|no_hp|alamat|address",
            "source_json",
            "free_text",
        ):
            self.assertIn(prohibited, CHECK_SQL)


if __name__ == "__main__":
    unittest.main()
