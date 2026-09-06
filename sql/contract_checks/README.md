# SQL contract checks

Checks in this directory will validate required columns, row grain,
reconciliation totals, date ranges, and the absence of patient identifiers from
public aggregate views.

Run `10_sigizi_monitoring_checks.sql` after deploying the SIGIZI views. It
checks the retained source family, deletion reconciliation, stage grain, and
public column names.
