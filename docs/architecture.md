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
SIGIZI–EPUS Monitoring R Shiny application
```

## Ownership boundary

The upstream `birth-outcome` pipeline owns source adapters, identity cleaning,
pregnancy assignment, source reconciliation, canonical ANC encounters,
delivery linkage, and clinical outcome definitions.

This repository owns monitoring-specific aggregate views, query contracts,
dashboard modules, presentation logic, and application-level tests.

The application must not reimplement upstream eligibility, matching,
deduplication, or clinical classification logic.

