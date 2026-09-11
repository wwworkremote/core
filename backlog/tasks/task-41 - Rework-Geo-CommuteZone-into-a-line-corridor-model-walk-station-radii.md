---
id: TASK-41
title: 'Rework Geo::CommuteZone into a line-corridor model (walk + station radii)'
status: Done
assignee: []
created_date: '2026-08-14 17:31'
updated_date: '2026-08-14 19:42'
labels:
  - geo
  - job_postings
dependencies: []
priority: high
type: feature
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Geo::CommuteZone was a point-radius model: a circle around home plus one circle around a downtown centroid. That can't express a real hybrid-commute constraint, which is often a *corridor*: acceptable anywhere near a stop on a commuter-rail line, OR within walking distance of that line's downtown terminals — not the whole downtown. Replace the single downtown circle with (a) a station-proximity radius checked against each stop on the target line and (b) a tight walk radius around the terminals. Keep the home hyperlocal radius. All places geocoded through the existing Geocoder/cache path, no hardcoded lat/lngs. No personal address or route data in code — see AC #4.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Geo::CommuteZone recognizes a job near any configured line stop as :allowed
- [ ] #2 Geo::CommuteZone only allows downtown locations within a tight walk radius of the configured terminals, not the whole downtown
- [ ] #3 Existing hyperlocal/remote/blocked spec behavior in commute_zone_spec.rb still passes
- [ ] #4 The route (stops, terminals, radii, home) is data/config, never committed to the repo
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the flat single-centroid circle with a line-corridor model: a tight walk radius around the two downtown transit terminals, plus a station radius around every stop on the target commuter-rail line, geocoded through the existing Geocoder/cache path -- no hardcoded lat/lngs. Home hyperlocal radius unchanged. Updated admin/pipeline_filters and rewrote commute_zone_spec.rb for the new zone shape. Verified the geometry against real geocoded coordinates before landing.

**Superseded (later exposure pass):** the hardcoded terminal/station/radius constants are gone. The whole zone is now data — `config/commute_zone.yml` (gitignored): a home point + radius plus named zones, each a list of geocoded places and a radius. No file → the filter is inert. Shape: `config/commute_zone.yml.example`.
<!-- SECTION:FINAL_SUMMARY:END -->
