# Installing NzbDav on CasaOS

This guide installs NzbDav on an Ubuntu server running [CasaOS](https://casaos.io/) by pasting a Docker Compose file.

## Prerequisites

- Ubuntu server with CasaOS installed
- A usenet provider account

## Install via Compose import

### Step 1: Open the custom app installer

1. Log in to your CasaOS dashboard (`http://<your-server-ip>`).
2. Open **App Store**.
3. Click **Install a customized app** (or **Custom Install**).
4. Click the **Import** button in the top-right corner of the compose editor.

### Step 2: Paste the compose file

Copy the compose file from this URL and paste it into the text box:

```
https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml
```

Or open that link in a browser, copy all the YAML, and paste it into CasaOS.

Click **Submit** / **OK**, then **Install**.

### Step 3: First-time configuration

1. Open NzbDav from the CasaOS dashboard (or go to `http://<your-server-ip>:3000`).
2. **Create admin account** — set your login username and password.
3. **Usenet settings** (`Settings` → `Usenet`):
   - Host, port, username, and password from your usenet provider
   - Set max connections to your provider's limit
4. **WebDAV settings** (`Settings` → `WebDAV`):
   - Set a WebDAV username and password

## Copy-paste compose file

If you prefer to copy directly from here:

```yaml
name: nzbdav
services:
  nzbdav:
    cpu_shares: 90
    container_name: nzbdav
    deploy:
      resources:
        reservations:
          memory: "512M"
    environment:
      PGID: $PGID
      PUID: $PUID
      TZ: $TZ
    healthcheck:
      test: curl -f http://localhost:3000/health || exit 1
      interval: 1m
      retries: 3
      start_period: 30s
      timeout: 10s
    image: nzbdav/nzbdav:0.6.4
    labels:
      icon: https://cdn.jsdelivr.net/gh/killamfkr/nzbdav@main/Apps/NzbDav/icon.png
    network_mode: bridge
    ports:
      - target: 3000
        published: "3000"
        protocol: tcp
    restart: unless-stopped
    volumes:
      - type: bind
        source: /DATA/AppData/nzbdav/config
        target: /config
      - type: bind
        source: /DATA/remote
        target: /mnt
    x-casaos:
      envs:
        - container: TZ
          description:
            en_US: Time zone
        - container: PUID
          description:
            en_US: User ID
        - container: PGID
          description:
            en_US: Group ID
      ports:
        - container: "3000"
          description:
            en_US: Web UI and WebDAV port
      volumes:
        - container: /config
          description:
            en_US: Config and database
        - container: /mnt
          description:
            en_US: Rclone mount point
x-casaos:
  architectures:
    - amd64
    - arm64
  author: NzbDav
  category: Media
  description:
    en_US: WebDAV server for streaming usenet content. SABnzbd-compatible API for Sonarr/Radarr.
  developer: NzbDav
  icon: https://cdn.jsdelivr.net/gh/killamfkr/nzbdav@main/Apps/NzbDav/icon.png
  index: /
  main: nzbdav
  port_map: "3000"
  tagline:
    en_US: Stream usenet content over WebDAV without local storage
  title:
    en_US: NzbDav
  version: "0.6.4"
```

> **Port already in use?** Change `published: "3000"` to another port (e.g. `"3001"`) and update `port_map: "3001"` at the bottom.

## Data locations

| Path on server | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/config` | Settings, database, and persistent config |
| `/DATA/remote` | Rclone mount point (`/mnt` inside the container) |

CasaOS creates these folders on first start. Config is kept if you uninstall with **keep user data** enabled.

## Radarr / Sonarr / Plex integration

For the full infinite-library setup with Rclone, see the [comprehensive setup guide](setup-guide.md).

- Use `/DATA/remote` on the host for Rclone mounts
- Point Radarr/Sonarr to NzbDav at `http://<server-ip>:3000` as a SABnzbd download client

## Updating

1. Open the NzbDav app in CasaOS → **Settings** → **Compose**.
2. Change the image tag (e.g. `nzbdav/nzbdav:0.6.4` → newer version).
3. Save and restart the app.

## Troubleshooting

| Issue | Solution |
|---|---|
| App won't start | Check logs in CasaOS. Ensure port 3000 is free or change the published port. |
| Permission errors | Run `id` over SSH and match PUID/PGID in the compose file if needed. |
| Blank tile / no icon | The `labels.icon` line sets the dashboard icon; check your server can reach GitHub. |
| Radarr/Sonarr can't connect | Use the server LAN IP, not `localhost`, from other containers. |

## SSH install (alternative)

```bash
mkdir -p /DATA/AppData/nzbdav/config /DATA/remote
curl -fsSL -o /tmp/nzbdav-compose.yml \
  https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml
docker compose -f /tmp/nzbdav-compose.yml up -d
```
