# Remote Devices — the tower's fleet interface

The Remote Devices rapplication: one click from the tower onto any machine in
the fleet, over Tailscale, via macOS Screen Sharing (`vnc://` MagicDNS names).
This is how the control tower is operated ACROSS the fleet — sit at any device,
open the tower, jump to any other device.

## Files

- **`devices.json`** — the fleet registry (single source of truth). The tower
  dashboard (`tools/dashboard.sh`) reads it at generation time and renders the
  fleet strip at the top of the board, with LIVE per-device online status from
  `tailscale status` (the standalone app only shows a static badge).
- **`index.html`** — the standalone app UI, byte-identical to what the installed
  Mac app serves (`/Applications/Remote Devices.app/Contents/Resources/index.html`,
  sha1 `ebec1565…`). Fully self-contained; open it anywhere.

## Adding a device

1. Add an entry to `devices.json` (`name`, `platform`, `host`) — the dashboard
   picks it up on next regeneration, no other change needed.
2. Optionally mirror a card in `index.html` and copy it into the app bundle:
   `cp remote-devices/index.html "/Applications/Remote Devices.app/Contents/Resources/index.html"`

## Boundary

Tailnet hostnames live here because the tower is PRIVATE (iron law 7). Never
copy `devices.json` or these hostnames into a public repo or artifact.
