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

## The federated layer — satellite towers (`satellite/`)

Every device runs `satellite/satellite.py` on tailnet port **7799** — a
device-local control tower pointing back to the main one:

- `http://<device>:7799/` — that device's own tower board (its live status +
  the whole fleet, probed client-side) with a **⬆ Main Tower Board** button.
- `http://<device>:7799/status.json` — CORS-open live status (brainstem probe,
  open rapp ports, disk, load). The main dashboard's fleet cards drill into this.
- On the MAIN device only: `/tower` serves the full `dashboard.html` board
  fleet-wide (regenerated in the background when stale), and `/install.sh`,
  `/satellite.py`, `/devices.json` let a new device bootstrap FROM the tower:

      curl -fsSL http://kodys-macbook-pro.tail99115f.ts.net:7799/install.sh | bash

  (macOS: installs to `~/.rapp-tower-satellite` + a KeepAlive LaunchAgent.
  Windows battlestation runs the same satellite.py via a logon scheduled task.)

**TCC note (macOS):** LaunchAgent python can't read `~/Documents`, so
`tools/dashboard.sh` publishes a copy of the board + git-rev meta into
`~/.rapp-tower-satellite/` on every regen; `/tower` serves that copy.

**Fleet decisions:** `tools/decisions.py` probes every device's satellite and
generates clickable cards — install-the-satellite for uncovered devices,
brainstem-down, disk-low — alongside the estate items. Your click queues the
action; a session executes it ON that device (ssh where keyed, else the
install one-liner over Screen Sharing).

## Adding a device

1. Add an entry to `devices.json` (`name`, `platform`, `host`) — the dashboard
   picks it up on next regeneration, no other change needed.
2. Optionally mirror a card in `index.html` and copy it into the app bundle:
   `cp remote-devices/index.html "/Applications/Remote Devices.app/Contents/Resources/index.html"`

## Boundary

Tailnet hostnames live here because the tower is PRIVATE (iron law 7). Never
copy `devices.json` or these hostnames into a public repo or artifact.
