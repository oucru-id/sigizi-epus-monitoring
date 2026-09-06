# Tests

Run the source-level SIGIZI checks from the repository root:

```powershell
Rscript tests/test_sigizi_monitoring.R
python -m unittest discover -s tests -p "test_*.py"
```

These checks validate the public-column guard, disabled render mode, five-source
mapping, deletion-registry boundary, PNC readiness state, and small-cell
suppression contract. They do not replace BigQuery execution of
`sql/contract_checks/10_sigizi_monitoring_checks.sql`.

Tests will cover SQL contracts, aggregate reconciliation, parameterized query
helpers, privacy gates, and Quarto rendering.
