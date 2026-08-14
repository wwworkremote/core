---
id: TASK-44
title: Interactive map for commute zone (UP-NW stations + terminal radii)
status: To Do
assignee: []
created_date: '2026-08-14 19:31'
labels:
  - ux
  - geo
dependencies:
  - TASK-41
priority: low
type: enhancement
ordinal: 50000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike likes interactive maps and already has maxmind-geoip2 in the Gemfile (used for IP geocoding). Once TASK-41 lands, Geo::CommuteZone::TERMINALS and UP_NW_STATIONS are a real geographic shape (a line of ~19 points + two walk-radius circles + home hyperlocal circle), not just a stat block -- worth visualizing on the admin/pipeline_filters page (Commute Zone card) as an actual map instead of numbers, and possibly on job_postings#index to show a geocoded posting's location relative to the zone. No map library currently in the app (checked Gemfile/package.json/app -- no leaflet/mapbox/maplibre). Leaflet via importmap (no build step, MIT license, works from a CDN or vendored asset) is the lightest option that fits the existing no-Node-bundler-for-Ruby-views approach.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Admin pipeline_filters Commute Zone card renders an interactive map showing home (approx), UP-NW stations, and Ogilvie/Union walk radii
- [ ] #2 No new JS build tooling required -- importmap or vendored asset only
- [ ] #3 Map degrades gracefully (no JS error) if HOME_LOCATION is unset
<!-- AC:END -->
