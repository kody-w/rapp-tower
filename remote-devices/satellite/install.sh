#!/bin/bash
# install.sh — bootstrap a RAPP tower satellite on this device, FROM the main tower:
#   curl -fsSL http://kodys-macbook-pro.tail99115f.ts.net:7799/install.sh | bash
# macOS: installs to ~/.rapp-tower-satellite + a LaunchAgent (KeepAlive) on :7799.
set -euo pipefail

MAIN="${RAPP_TOWER_MAIN:-kodys-macbook-pro.tail99115f.ts.net}"
PORT="${RAPP_TOWER_PORT:-7799}"
DEST="$HOME/.rapp-tower-satellite"
mkdir -p "$DEST"

echo "→ pulling satellite from the main tower ($MAIN:$PORT)"
curl -fsSL "http://$MAIN:$PORT/satellite.py"  -o "$DEST/satellite.py"
curl -fsSL "http://$MAIN:$PORT/devices.json"  -o "$DEST/devices.json"

# own tailnet identity (Tailscale MagicDNS name)
TS="tailscale"; command -v tailscale >/dev/null 2>&1 || TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
FQDN="$("$TS" status --json 2>/dev/null | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))' 2>/dev/null || hostname -f)"
ROLE="satellite"; [ "$FQDN" = "$MAIN" ] && ROLE="main"
printf '{"host":"%s","main":"%s","port":%s,"role":"%s"}\n' "$FQDN" "$MAIN" "$PORT" "$ROLE" > "$DEST/satellite.json"
echo "→ identity: $FQDN ($ROLE)"

PLIST="$HOME/Library/LaunchAgents/com.rapp.tower.satellite.plist"
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rapp.tower.satellite</string>
  <key>ProgramArguments</key><array>
    <string>/usr/bin/python3</string><string>$DEST/satellite.py</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$DEST/satellite.log</string>
  <key>StandardErrorPath</key><string>$DEST/satellite.log</string>
</dict></plist>
EOF
launchctl bootout "gui/$(id -u)/com.rapp.tower.satellite" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 2
if curl -fsS -m 3 "http://127.0.0.1:$PORT/status.json" >/dev/null; then
  echo "✅ satellite tower UP on :$PORT — board: http://$FQDN:$PORT/  (main: http://$MAIN:$PORT/tower)"
else
  echo "✗ satellite did not answer on :$PORT — see $DEST/satellite.log"; exit 1
fi
