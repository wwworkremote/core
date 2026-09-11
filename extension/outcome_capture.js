// WWWorkRemote — Outcome Capture
//
// On myjobs.indeed.com and my.greenhouse.io, re-issues each page's own
// authenticated fetch (same-origin, same session cookies Mike is already
// logged in with) and posts the raw response to the backend. No DOM
// scraping: both tracker pages already render from this exact JSON, so
// reading it directly is simpler and less selector-fragile than parsing
// rendered HTML the way the bin/import_* HAR-replay scripts have to. Those
// importers and this script both write through the matching
// Applications::*RowImporter server-side, so there is one place per source
// that understands the payload shape, not two.
//
// Fires once per page load, quietly. Mike doesn't do anything to trigger
// this beyond visiting a page he already visits.

(function () {
  'use strict';

  const ts = () => new Date().toISOString().slice(11, 23);
  const LOG = (...a) => console.log(`%c[WWWR-Outcome ${ts()}]`, 'color:#80c5ff;font-weight:bold', ...a);
  const LOG_OK = (...a) => console.log(`%c[WWWR-Outcome ${ts()}] ✓`, 'color:#8aff80;font-weight:bold', ...a);
  const LOG_ERR = (...a) => console.error(`%c[WWWR-Outcome ${ts()}] ✗`, 'color:#ff9580;font-weight:bold', ...a);

  const DEFAULT_API = 'http://localhost:31000';

  async function getApiBase() {
    return new Promise(resolve => {
      try {
        chrome.storage.local.get(['apiUrl'], cfg => resolve((cfg.apiUrl || DEFAULT_API).replace(/\/$/, '')));
      } catch (_) {
        resolve(DEFAULT_API);
      }
    });
  }

  async function postToBackend(path, body) {
    const apiBase = await getApiBase();
    const res = await fetch(`${apiBase}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`${path} HTTP ${res.status}`);
    return res.json();
  }

  // ─── Indeed ─────────────────────────────────────────────────────────────

  async function fetchAppStatusJobs() {
    const res = await fetch('https://myjobs.indeed.com/api/v1/appStatusJobs', { credentials: 'include' });
    if (!res.ok) throw new Error(`appStatusJobs HTTP ${res.status}`);
    return res.json();
  }

  async function runIndeed() {
    const payload = await fetchAppStatusJobs();
    const count = payload?.body?.appStatusJobs?.length || 0;
    if (!count) return LOG('appStatusJobs empty -- nothing to sync');

    const result = await postToBackend('/api/v0/outcomes/indeed', payload);
    LOG_OK(`Indeed: synced ${result.imported} application(s), ${result.outcomes} carrying an outcome`);
  }

  // ─── Greenhouse ─────────────────────────────────────────────────────────
  //
  // Paginated, unlike Indeed's single response -- fetch page 1, read its
  // reported total_pages, then fetch the rest. Omitting active_only (rather
  // than pinning it true, the way the one-time HAR backfill captured it) is
  // deliberate: if Greenhouse's default response also includes an inactive
  // bucket, this becomes the only path in the app that can see a rejection
  // there. Unverified against a live response as of writing -- the backend
  // reads inactive.applications defensively and no-ops if it isn't present,
  // so this is safe to try either way.

  async function fetchGreenhousePage(page) {
    const res = await fetch(`https://my.greenhouse.io/applications.json?page=${page}`, { credentials: 'include' });
    if (!res.ok) throw new Error(`applications.json HTTP ${res.status}`);
    return res.json();
  }

  async function fetchAllGreenhousePages() {
    const first = await fetchGreenhousePage(1);
    const totalPages = first?.active?.total_pages || 1;
    const pages = [first];
    for (let page = 2; page <= totalPages; page += 1) {
      // Sequential on purpose -- Greenhouse's own pagination is sequential, nothing to parallelize against.
      pages.push(await fetchGreenhousePage(page));
    }
    return pages;
  }

  async function runGreenhouse() {
    const pages = await fetchAllGreenhousePages();
    const result = await postToBackend('/api/v0/outcomes/greenhouse', { pages });
    LOG_OK(`Greenhouse: synced ${result.imported} application(s), ${result.outcomes} carrying an outcome`);
  }

  // ─── Dispatch ───────────────────────────────────────────────────────────

  async function run() {
    try {
      if (location.hostname === 'myjobs.indeed.com') await runIndeed();
      else if (location.hostname === 'my.greenhouse.io') await runGreenhouse();
    } catch (err) {
      // Never surface to Mike -- this runs silently on every visit. A failure
      // here (backend down, an API shape changed) shouldn't interrupt
      // browsing his own applications, only skip this sync.
      LOG_ERR(err.message || err);
    }
  }

  run();
})();
