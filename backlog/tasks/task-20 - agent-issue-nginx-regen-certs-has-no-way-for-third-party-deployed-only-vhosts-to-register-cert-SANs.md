---
id: TASK-20
title: >-
  [agent-issue] nginx-regen-certs has no way for third-party deployed-only
  vhosts to register cert SANs
status: To Do
assignee: []
created_date: '2026-07-27 18:16'
labels:
  - agent-reported
  - request
dependencies: []
priority: medium
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Type:** request
**Severity:** medium
**Trace ID:** `2cc836c037da4f0d6e5510e8727454ae`

Following the documented ops/nginx/servers/<name>.conf pattern (decision-011, same as ~/my/context-engine's my.conf) to add a new app vhost: wrote core/ops/nginx/servers/wwworkremote.conf, deployed it to $(brew --prefix)/etc/nginx/servers/wwworkremote.conf, ran nginx-regen-certs. HTTP routing worked immediately (curl -k gave 200 for both wwworkremote.localhost and wwwr.localhost), but the regenerated cert's SAN list did not include either hostname -- confirmed via 'openssl x509 -noout -ext subjectAltName', a real browser would show a cert mismatch warning. Root cause: nginx-regen-certs' SAN union only pulls from (1) the existing cert's current SANs and (2) grep of a hardcoded HOSTS=(...) bash array literally inside bin/nginx-ctl (currently: llama.localhost embed.localhost o2.localhost zdots.localhost gemstash.localhost my.localhost). There is no step that discovers hostnames from vhost files actually deployed to the servers/ directory (which is how deployed-only third-party configs, per sync_configs' own doc comment, are meant to coexist). my.localhost only appears because it happens to be hardcoded in that array, not because of any dynamic discovery -- any new app following the documented pattern gets working HTTP routing but silently no TLS cert coverage, discoverable only by manually diffing openssl's SAN output against what you expect. Worked around this time with a one-off manual mkcert run naming all hosts explicitly (which then persists via the existing-cert carry-forward), but the underlying gap remains for the next app that does this.

---
*Filed via `zdots-issue`. Operator review required before any changes are made.*
*Do not modify zdots to work around this issue — wait for operator resolution.*
<!-- SECTION:DESCRIPTION:END -->
