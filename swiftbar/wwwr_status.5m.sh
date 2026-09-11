#!/bin/bash
# <bitbar.title>wwwr pipeline status</bitbar.title>
# <bitbar.desc>Live pipeline status for wwworkremote/core, from bin/wwwr.</bitbar.desc>
# <bitbar.author>Mike Hall</bitbar.author>
#
# Not run directly from the repo -- SwiftBar only picks up scripts inside
# $HOME/.swiftbar/. Symlink or copy this there to activate it:
#   ln -s "$(pwd)/swiftbar/wwwr_status.5m.sh" "$HOME/.swiftbar/wwwr_status.5m.sh"
# The refresh interval (5m) is encoded in the filename per SwiftBar
# convention -- rename to change it (e.g. wwwr_status.1m.sh).
#
# WWWR is hardcoded rather than derived from this script's own path: once
# symlinked into $HOME/.swiftbar, this script's location no longer has any
# relation to the repo it's calling into -- every SwiftBar plugin that
# shells into a specific project ends up pinned to that project's path.
WWWR="/Users/mike/github.com/wwworkremote/wwworkremote/bin/wwwr"

# bin/wwwr boots the full Rails app, which logs OpenTelemetry/instrumentation
# lines straight to stdout regardless of RAILS_ENV -- strip those so they
# don't show up as garbage dropdown entries.
clean() { grep -Ev '^[IWEF], \['; }

STATUS=$("$WWWR" status 2>/dev/null | clean)
PENDING=$(echo "$STATUS" | awk -F': *' '/Pending documents/ {print $2}')

echo "wwwr: ${PENDING:-?} pending"
echo "---"
while IFS= read -r line; do echo "  $line"; done <<<"$STATUS"
echo "---"
echo "Recent postings | size=11"
"$WWWR" postings 2>/dev/null | clean | while IFS= read -r line; do
  id="${line#\#}"
  id="${id%% *}"
  echo "$line | font=Menlo size=11 bash=\"$WWWR\" param1=transition param2=\"$id\" param3=ignore terminal=false refresh=true"
done
echo "---"
echo "Refresh | refresh=true"
