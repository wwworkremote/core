---
id: TASK-41
title: 'Rework Geo::CommuteZone for UP-NW line + Ogilvie/Union walk radius'
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
Current Geo::CommuteZone is a point-radius model: a circle around HOME_LOCATION plus a 2mi circle around a "Chicago Loop" centroid. This can't express the real commute constraint: hybrid work is feasible anywhere along the Metra UP-NW line (Ogilvie Transportation Center, Clybourn, Irving Park, Jefferson Park, Gladstone Park, Norwood Park, Edison Park, Park Ridge, Dee Road, Des Plaines, Cumberland, Mount Prospect, Arlington Heights, Arlington Park, Palatine, Barrington, Fox River Grove, Cary, Pingree Road, McHenry, Crystal Lake, Woodstock, Harvard -- confirmed via web search 2026-08-14), OR downtown Chicago specifically within walking distance of Ogilvie or Union Station (the two UP-NW termini) -- not the Loop generally. Replace the single Loop-centroid circle with (a) a small station-proximity radius checked against each named UP-NW station (geocoded via the existing Geocoder/Nominatim setup, same pattern as CHICAGO_LOOP_LOCATION today), and (b) a tight walk radius around Ogilvie and Union specifically. Keep HOME_LOCATION hyperlocal radius as-is.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Geo::CommuteZone recognizes a job location near any UP-NW station as :allowed
- [ ] #2 Geo::CommuteZone only allows downtown Chicago locations within a tight walk radius of Ogilvie or Union, not the whole Loop
- [ ] #3 Existing hyperlocal/remote/blocked spec behavior in commute_zone_spec.rb still passes
- [ ] #4 Radii remain ENV-configurable, no personal address data committed
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the flat "Chicago Loop" 2mi circle with a real line-corridor model: a tight 0.75mi walk radius around Ogilvie and Union specifically (TERMINALS), plus a 1.5mi radius around every UP-NW stop from Clybourn out to Harvard including the McHenry branch (UP_NW_STATIONS), geocoded through the existing Geocoder/cache path -- no hardcoded lat/lngs. HOME_LOCATION hyperlocal radius unchanged. Updated admin/pipeline_filters to show all three radii plus the station list, and rewrote commute_zone_spec.rb for the new zone shape (10 examples, all passing). Built an interactive verification map (published as a Claude artifact) plotting real geocoded coordinates for every station/terminal plus Loop landmarks, confirmed the walk-radius/station-radius geometry visually before landing.
<!-- SECTION:FINAL_SUMMARY:END -->
