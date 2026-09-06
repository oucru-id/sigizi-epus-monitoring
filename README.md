# SIGIZI–EPUS Monitoring

Static Quarto/R monitoring website for antenatal care (ANC), intranatal care
(INC), and postnatal care (PNC) recorded across SIGIZI and ePuskesmas
(EPUS) sources in Lombok Barat.

## Status

The initial SIGIZI monitoring section and its aggregate BigQuery view contracts
are implemented. The website still renders safely without a BigQuery
connection; operational counts remain disabled until the views are deployed
and a controlled render identity is configured.

## Data boundary

The `birth-outcome` repository remains the authoritative upstream pipeline for
source cleaning, pregnancy construction, cross-source matching, deduplication,
and outcome logic.

This project will consume curated BigQuery objects maintained by that pipeline:

- Project: `spheres-lombok-barat`
- Upstream dataset: `kohort_bumil_v3`
- BigQuery location: `asia-southeast2`

Monitoring-specific aggregate views should be created in a separately managed
dataset, proposed as `spheres-lombok-barat.sigizi_epus_monitoring`, after its
name, permissions, and live source contracts have been approved.

## Initial scope

- Source freshness and record-volume monitoring
- ANC visits and K1–K6 coverage
- INC/delivery recording coverage
- PNC visits and KF1–KF4 coverage
- SIGIZI versus EPUS source coverage
- Aggregate data-quality indicators
- Aggregate data-contract and reconciliation checks

Raw source-record counts, canonical visit counts, unique pregnancy counts, and
delivery/baby counts will remain separate measures. R will query curated views
during rendering rather than reproduce clinical matching logic.

The SIGIZI source-to-stage contract is documented in
[`docs/sigizi-monitoring-contract.md`](docs/sigizi-monitoring-contract.md).
Its `daftar ibu hamil hapus` input is an exclusion registry, not a clinical
source, and is never added to service totals.

## Render locally

Prerequisites:

- R with `knitr` and `rmarkdown`
- Quarto CLI

From PowerShell in the repository root:

```powershell
& "C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe" render
```

Rendered files are written to `_site/`. Preview locally with:

```powershell
& "C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe" preview
```

## GitHub Pages

- `.github/workflows/render-check.yml` verifies the site on pushes and pull
  requests without publishing it.
- `.github/workflows/publish.yml` publishes to the `gh-pages` branch only when
  manually started from the GitHub Actions page.
- The public site must contain approved aggregate measures only.

The expected project-site URL, after publication is enabled, is:

`https://oucru-id.github.io/sigizi-epus-monitoring/`

## Privacy and security

- This repository and its GitHub Pages site are public; treat every committed
  and rendered file as downloadable.
- Never commit credentials, service-account keys, row-level exports, or
  identifiable screenshots.
- Do not log patient identifiers.
- Do not publish record-level worklists or downloadable row-level extracts.
- Treat rendered HTML and JavaScript as downloadable data.
