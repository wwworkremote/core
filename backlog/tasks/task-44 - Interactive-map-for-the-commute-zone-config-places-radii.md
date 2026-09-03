---
id: TASK-44
title: Interactive map for the commute-zone config (places + radii)
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
Mike likes interactive maps and already has maxmind-geoip2 in the Gemfile (used for IP geocoding). `Geo::CommuteZone` is now config-driven (`config/commute_zone.yml`, gitignored): a home point + radius plus named zones, each a list of geocoded places and a radius. That's a real geographic shape (points + radius circles), not just a stat block -- worth visualizing on the admin/pipeline_filters page (Commute Zone card) as an actual map instead of chips, reading `Geo::CommuteZone.zones` / `.home_radius_miles`, and possibly on job_postings#index to show a geocoded posting's location relative to the zone. No map library currently in the app (checked Gemfile/package.json/app -- no leaflet/mapbox/maplibre). Leaflet via importmap (no build step, MIT license, works from a CDN or vendored asset) is the lightest option that fits the existing no-Node-bundler-for-Ruby-views approach.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Admin pipeline_filters Commute Zone card renders an interactive map showing home (approx) and the configured zone places with their radii
- [ ] #2 No new JS build tooling required -- importmap or vendored asset only
- [ ] #3 Map degrades gracefully (no JS error) if HOME_LOCATION is unset
<!-- AC:END -->
