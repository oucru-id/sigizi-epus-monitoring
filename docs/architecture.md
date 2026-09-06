# Architecture

```text
Raw SIGIZI and EPUS sources
             |
             v
birth-outcome pipeline
spheres-lombok-barat.kohort_bumil_v3
             |
             v
Monitoring-specific curated aggregate views
spheres-lombok-barat.sigizi_epus_monitoring (proposed)
             |
             v
SIGIZI–EPUS static Quarto/R website
```

## Ownership boundary

The upstream `birth-outcome` pipeline owns source adapters, identity cleaning,
pregnancy assignment, source reconciliation, canonical ANC encounters,
delivery linkage, and clinical outcome definitions.

This repository owns monitoring-specific aggregate views, query contracts,
Quarto pages, presentation logic, and render-level tests.

The website must not reimplement upstream eligibility, matching,
deduplication, or clinical classification logic.

## Refresh model

R executes at render time, not when a reader opens the website. A controlled
render may query approved aggregate BigQuery views and then produce static HTML,
CSS, and JavaScript for GitHub Pages.

Every value embedded in the rendered output must be considered downloadable.
The published site therefore excludes names, NIKs, telephone numbers, addresses,
free text, source JSON, and row-level worklists.
