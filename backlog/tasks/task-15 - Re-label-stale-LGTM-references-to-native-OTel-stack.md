---
id: TASK-15
title: Re-label stale LGTM references to native OTel stack
status: Done
assignee: []
created_date: '2026-07-27 17:27'
updated_date: '2026-08-27 17:59'
labels: []
dependencies: []
references:
  - docker-compose.yml
modified_files:
  - docker-compose.yml
priority: low
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docker-compose.yml comments still call the observability backend the 'LGTM stack' (Loki/Grafana/Tempo/Mimir). It's now native otelcol-contrib + OpenObserve. Port 4318 is unchanged so nothing is functionally broken, but the comment misleads the next reader/agent.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docker-compose.yml OTEL_EXPORTER_OTLP_ENDPOINT comment updated to reference otelcol-contrib + OpenObserve, not LGTM
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Both OTEL_EXPORTER_OTLP_ENDPOINT comments (web + worker services) updated from "LGTM stack" to "otelcol-contrib + OpenObserve".
<!-- SECTION:FINAL_SUMMARY:END -->
