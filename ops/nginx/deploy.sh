#!/usr/bin/env bash
# ops/nginx/deploy.sh — deploy wwworkremote's local .localhost nginx vhost.
#
# Distinct from bin/register-nginx-conf / bin/register-puma-service, which target
# the Linux production box (systemd, /etc/nginx/sites-available). This is for the
# local macOS dev setup: Homebrew nginx + mkcert, localhost and trusted-LAN home.arpa names,
# following the same ops/nginx/servers/<name>.conf pattern as ~/my/context-engine.
#
# Not run automatically by anything in this repo -- nginx/cert changes are
# operator-only on this machine. Run it yourself:
#   ops/nginx/deploy.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/nginx/servers/wwworkremote.conf"
BREW_PREFIX="$(brew --prefix)"
DST="$BREW_PREFIX/etc/nginx/servers/wwworkremote.conf"

if [[ ! -f "$SRC" ]]; then
  echo "error: $SRC not found" >&2
  exit 1
fi

echo "==> Deploying vhost source"
cp "$SRC" "$DST"
echo "    $SRC -> $DST"

echo "==> Regenerating cert (picks up new SANs, validates, reloads nginx)"
nginx-regen-certs

echo "==> Verifying (redirect-blind, per decision-011; cert-validating so a SAN gap fails loudly)"
for h in wwworkremote.localhost wwwr.localhost wwworkremote.home.arpa wwwr.home.arpa; do
  printf '    %s: ' "$h"
  curl -s "https://$h" -o /dev/null -w '%{http_code}\n' --max-redirs 0
done

echo "==> Done. Start the app with 'bin/dev' if it isn't already running."
