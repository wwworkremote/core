---
id: TASK-15
title: Re-label stale LGTM references to native OTel stack
status: To Do
assignee: []
created_date: '2026-07-27 17:27'
labels: []
dependencies: []
references:
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
- [ ] #1 docker-compose.yml OTEL_EXPORTER_OTLP_ENDPOINT comment updated to reference otelcol-contrib + OpenObserve, not LGTM
<!-- AC:END -->
