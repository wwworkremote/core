# Development Guide

This document outlines the process for setting up and running WWWorkRemote in a local development environment.

## 📋 Prerequisites

Ensure your system has the following core dependencies:

- **Ruby 4.0.2**: Managed via `mise` or `asdf`.
- **PostgreSQL 16+**: Must support `pgvector` and `pg_trgm`.
- **Node.js**: Required for Tailwind and Ingestion scripts.
- **llama.cpp**: A local LLM server must be running at `http://localhost:11500`.
- **Docker**: Optional, required for running local CI via `act`.

## 🚀 Local Setup

Run the automated setup script to install dependencies and prepare the database:

```bash
bin/setup
```

### 1. AI Model Registry
WWWorkRemote requires localized model definitions in the database to orchestrate jobs:

```bash
bin/rails ruby_llm:load_models
```

### 2. GeoIP Databases
For local location resolution, download the MaxMind Lite databases:

```bash
# Set your MaxMind credentials
export MAXMIND_ACCOUNT_ID="your_id"
export MAXMIND_LICENSE_KEY="your_key"

bin/update-geoip
```

See [docs/configuration.md](configuration.md) for detail on credential management.

## 🛠️ Running the System

### Application Server
Start the development server (Falcon):

```bash
bin/dev
```
Access the dashboard at `http://localhost:31000`.

### Background Workers
WWWorkRemote uses **Solid Queue**. Workers are automatically started by `bin/dev` via the `Procfile.dev`.

### EML Scanner
To scan your local Apple Mail exports for job postings:

```bash
bundle exec rake eml:scan
```
*Expected path: `~/.wwworkremote/*.eml`*

## ✅ Operational Verification (Smoke Tests)

Confirm the system is healthy after a major update:

- **Email Ingestion**: Place a `.eml` in `~/.wwworkremote/indeed/` and run `bundle exec rake eml:scan`.
- **AI Inference**: Run `ruby bin/verify_llm.rb` to check connectivity and responses.
- **Background Queue**: Access Mission Control at `/mounts/jobs` and confirm workers are active.
- **Analytics**: Verify `/admin/observability` charts render correctly.

## 📱 LAN / Mobile Access

The dev server is also reachable from other devices on the trusted LAN (e.g. a phone), via
`https://lan.wwworkremote.com`.

### How it's wired

- **DNS**: `lan.wwworkremote.com` is a real public A record in DNSimple, pointing at this
  Mac's DHCP-reserved LAN address (`10.36.1.149`). It resolves normally from anywhere (no
  special client setup needed), but only *connects* from the trusted LAN, since `10.36.1.149`
  isn't routable from outside it.

  This replaced an earlier `wwworkremote.home.arpa` + local AdGuard DNS rewrite approach.
  That failed silently: `dig` against the AdGuard server resolved the name fine, but macOS/iOS's
  actual resolver (`getaddrinfo`, used by Safari/curl/every real app) refuses to look up `.arpa`
  names at all. A `.local` name was tried too and is worse — it's reserved for mDNS/Bonjour, so
  an unadvertised `.local` name hangs for ~5s per request before failing, rather than failing
  fast. A real DNS record sidesteps both reserved-TLD behaviors.

- **nginx**: `ops/nginx/servers/wwworkremote.conf` (source-owned here) lists
  `lan.wwworkremote.com` alongside `wwworkremote.localhost`/`wwwr.localhost` in `server_name`,
  proxying all three to the same Puma backend on port `31000`.

- **TLS**: the cert is a local [mkcert](https://github.com/FiloSottile/mkcert) leaf cert, shared
  across every local app on this Mac (zdots-owned tooling, not this repo). It's not from a
  publicly trusted CA, so a phone will show a certificate-trust warning on first visit — expected,
  not a bug. Proceeding through that warning is currently how phone access works; installing
  mkcert's root CA on the phone would remove the warning but hasn't been done.

- **Rails**: `config/environments/development.rb` allowlists `lan.wwworkremote.com` in
  `config.hosts` — Rails rejects unrecognized `Host` headers by default. Note that setting
  `config.hosts` explicitly also drops Rails' own implicit "allow any `.localhost` subdomain in
  development" behavior, so the plain dev vhost names have to be listed too, not just the LAN one.

### Deploying a vhost/cert change

```bash
ops/nginx/deploy.sh
```

Operator-only (touches Homebrew's nginx config and regenerates the shared TLS cert via
`nginx-regen-certs`) — not run automatically by anything in this repo. It copies the vhost
source into Homebrew's nginx config dir, regenerates the cert so it covers every hostname
actually served (including any new `server_name` added to the vhost), reloads nginx, then
verifies all three hostnames respond with a real (non-`-k`) `curl` check.

### Known gaps

Tracked in `Backlog.md` under "LAN/mobile access": no firewall restriction to the trusted LAN
(currently open to anyone who can reach `10.36.1.149`), no distinct auth/session posture for a
second device, and mobile-responsive coverage is partial (shared nav, admin dashboard/jobs,
job-posting index/detail so far).

## 🔍 Debugging

- **Logs**: `tail -f log/development.log`
- **Job Monitoring**: Access the Mission Control dashboard at `/mounts/jobs`.
- **Database Performance**: Access PgHero at `/mounts/pghero`.
- **LLM Context**: Use the "Neural Dialogues" view to debug raw LLM prompts and responses.
