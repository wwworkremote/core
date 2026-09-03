# Pending changes in the just3ws.github.io repo

**Queue closed 2026-08-24 — nothing here is blocked.** The 2026-08 pass that
reconciled the canonical resume YAML against other sources (position `type:`
fields, a few title reframes, a community-history chronology fix, removing the
private `wwworkremote` entry from the public resume) is fully applied. Each
item landed as its own commit in `just3ws.github.io`.

The detailed decision record — which included career-narrative context that
does not belong in a functional-application repo — has moved to the private
vault (`~/my/`). New peer-repo work should start a fresh queue rather than
reopening this.

## What still matters here

- **Authority boundaries:** [`peer-contract-just3ws.md`](peer-contract-just3ws.md).
  That repo is **public**; the raw career narrative stays in the vault, only
  the neutral form goes in the YAML.
- **The repo stays private, as a whole.** Guardrails and application data live
  in one repo, so exposing any slice exposes all of it. Extracting a public
  subset is off the table.
- **`Resume::YamlImporter` does not read that repo's working tree.** It fetches
  `http://just3ws.localhost/resume.json`, so a YAML edit only reaches this app
  after a Jekyll build.
- **Do not batch peer-repo edits into one commit** — one commit per position
  fact keeps a wrong call revertible on its own.
