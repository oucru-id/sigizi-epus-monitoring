# SIGIZI–EPUS Monitoring

R Shiny monitoring dashboard for antenatal care (ANC), intranatal care
(INC), and postnatal care (PNC) recorded across SIGIZI and ePuskesmas
(EPUS) sources in Lombok Barat.

## Status

Initial repository scaffold. The dashboard does not yet connect to BigQuery
or expose operational data.

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
- Privacy-gated operational worklists, if authorized

Raw source-record counts, canonical visit counts, unique pregnancy counts, and
delivery/baby counts will remain separate measures. The Shiny application will
query curated views rather than reproduce clinical matching logic in R.

## Run locally

Prerequisites will be finalized with the BigQuery data contract. For the
placeholder application, install Shiny and run:

```r
install.packages("shiny")
shiny::runApp()
```

The default local address is printed by Shiny when the application starts.

## Privacy and security

- Keep this repository private.
- Never commit credentials, service-account keys, row-level exports, or
  identifiable screenshots.
- Do not log patient identifiers.
- Generate record-level CSV files only through an explicit, authorized download.

