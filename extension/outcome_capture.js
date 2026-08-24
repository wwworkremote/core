// WWWorkRemote — Outcome Capture
//
// On myjobs.indeed.com, re-issues the page's own authenticated
// api/v1/appStatusJobs fetch (same-origin, same session cookies Mike is
// already logged in with) and posts the raw response to the backend.
// No DOM scraping: the tracker page already renders from this exact JSON,
// so reading it directly is both simpler and less selector-fragile than
// parsing rendered HTML the way bin/import_indeed_applications' HAR replay
// has to. That importer and this script both write through
// Applications::IndeedRowImporter server-side, so there is one place that
// understands the payload shape, not two.
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

  // credentials: 'include' is the whole mechanism -- this fetch runs in the
  // page's own origin, so it carries the exact cookies myjobs.indeed.com's
  // own client-side code uses. No token, no login flow of our own.
  async function fetchAppStatusJobs() {
    const res = await fetch('https://myjobs.indeed.com/api/v1/appStatusJobs', { credentials: 'include' });
    if (!res.ok) throw new Error(`appStatusJobs HTTP ${res.status}`);
    return res.json();
  }

  async function postToBackend(body) {
    const apiBase = await getApiBase();
    const res = await fetch(`${apiBase}/api/v0/outcomes/indeed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`outcomes/indeed HTTP ${res.status}`);
    return res.json();
  }

  async function run() {
    try {
      const payload = await fetchAppStatusJobs();
      const count = payload?.body?.appStatusJobs?.length || 0;
      if (!count) return LOG('appStatusJobs empty -- nothing to sync');

      const result = await postToBackend(payload);
      LOG_OK(`synced ${result.imported} application(s), ${result.outcomes} carrying an outcome`);
    } catch (err) {
      // Never surface to Mike -- this runs silently on every visit. A failure
      // here (backend down, Indeed API shape changed) shouldn't interrupt
      // browsing his own applications, only skip this sync.
      LOG_ERR(err.message || err);
    }
  }

  run();
})();
