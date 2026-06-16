# Installing NzbDav on CasaOS

This guide walks through installing NzbDav on an Ubuntu server running [CasaOS](https://casaos.io/).

## Prerequisites

- Ubuntu server with CasaOS installed ([installation guide](https://wiki.casaos.io/en/quick/start))
- A usenet provider account (required for streaming content)

## One-click install

### Step 1: Add the NzbDav app store

1. Log in to your CasaOS dashboard (usually `http://<your-server-ip>`).
2. Open **App Store**.
3. Click the **⋮** menu in the top-right corner.
4. Select **Import a Zip or URL**.
5. Enter the following URL and confirm:

   ```
   https://github.com/killamfkr/nzbdav/archive/refs/heads/main.zip
   ```

CasaOS downloads the app store bundle from this repository. **NzbDav** appears in your available apps.

### Step 2: Install NzbDav

1. Search for **NzbDav** in the App Store.
2. Click **Install**.
3. Review the pre-install notes (first-time setup steps).
4. Accept the default settings or adjust:
   - **Web UI port** — defaults to `3000` if available
   - **PUID / PGID** — usually `1000` on CasaOS
5. Click **Install** and wait for the container to start.

### Step 3: First-time configuration

1. Open NzbDav from the CasaOS dashboard (or browse to `http://<your-server-ip>:3000`).
2. **Create admin account** — set your login username and password.
3. **Usenet settings** (`Settings` → `Usenet`):
   - Host, port, username, and password from your usenet provider
   - Set max connections to your provider's limit
4. **WebDAV settings** (`Settings` → `WebDAV`):
   - Set a WebDAV username and password (used by Rclone and other clients)

Your NzbDav instance is ready for basic use.

## Data locations on CasaOS

| Path on server | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/config` | Settings, database, and persistent config |
| `/DATA/remote` | Mount point for Rclone remote storage (`/mnt` inside container) |

Config survives app restarts and reinstalls as long as you keep the **user data** option enabled when uninstalling.

## Integrating with Radarr, Sonarr, and Plex

For the full "infinite library" setup with Rclone sidecar, symlink folders, and media server integration, follow the [comprehensive setup guide](setup-guide.md). Key points for CasaOS:

- Use `/DATA/remote` on the host (mapped to `/mnt` in the container) for Rclone mounts.
- Point Radarr/Sonarr download client to NzbDav's SABnzbd-compatible API at `http://<server-ip>:3000`.
- See Phase 2–4 of the setup guide for Rclone and Arr configuration.

## Updating NzbDav

1. In CasaOS, open the NzbDav app settings.
2. Check for updates in the App Store, or edit the image tag in the compose file to a newer version (e.g. `nzbdav/nzbdav:0.6.4`).
3. Restart the app.

## Troubleshooting

| Issue | Solution |
|---|---|
| App won't start | Check logs in CasaOS → NzbDav → Logs. Ensure port 3000 is not in use. |
| Permission errors on config | Verify PUID/PGID match your CasaOS user (`id` in SSH). |
| Can't connect to usenet | Double-check provider host, port `563` (SSL), and credentials in Settings. |
| Radarr/Sonarr can't reach NzbDav | Use the server LAN IP and the port shown in CasaOS (not `localhost` from other containers unless on the same Docker network). |

## Manual install (without App Store)

If you prefer SSH, copy the compose file and run it directly:

```bash
mkdir -p /DATA/AppData/nzbdav/config /DATA/remote
curl -fsSL -o /DATA/AppData/casaos/apps/nzbdav/docker-compose.yml \
  https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml
cd /DATA/AppData/casaos/apps/nzbdav
docker compose up -d
```

Then import or manage the app from the CasaOS UI.
