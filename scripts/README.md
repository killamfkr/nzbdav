# NzbDav CasaOS Installer

One-command installer for **NzbDav + Rclone** on Ubuntu servers running [CasaOS](https://casaos.io/).

The script installs both containers, generates `rclone.conf`, creates your admin account, configures WebDAV and usenet, and mounts the WebDAV share at `/DATA/remote/nzbdav`. No manual compose editing required.

## Non-interactive install (recommended)

SSH into your server and run **one line**:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo NZBDAV_ADMIN_PASS='your-admin-password' NZBDAV_WEBDAV_PASS='your-webdav-password' USENET_HOST='news.newshosting.com' USENET_USER='your-usenet-user' USENET_PASS='your-usenet-pass' bash
```

Replace the placeholder values with your real credentials.

When it finishes:

- Web UI: `http://<your-server-ip>:3000`
- Credentials saved to: `/DATA/AppData/nzbdav/credentials.txt`
- Rclone mount: `/DATA/remote/nzbdav`

### Example

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='MySecureAdmin123' \
  NZBDAV_WEBDAV_PASS='MySecureWebdav123' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='nh12345' \
  USENET_PASS='my-usenet-password' \
  bash
```

> **Tip:** Paste the entire command on a single line, or use the multi-line version above. Do not break the URL across lines.

## Required environment variables

| Variable | Description |
|---|---|
| `NZBDAV_ADMIN_PASS` | Password for the NzbDav web UI login |
| `NZBDAV_WEBDAV_PASS` | Password for WebDAV / Rclone access |
| `USENET_HOST` | Usenet provider hostname (e.g. `news.newshosting.com`) |
| `USENET_USER` | Usenet username |
| `USENET_PASS` | Usenet password |

## Optional environment variables

| Variable | Default | Description |
|---|---|---|
| `NZBDAV_ADMIN_USER` | `admin` | Web UI login username |
| `NZBDAV_WEBDAV_USER` | `admin` | WebDAV username |
| `USENET_PORT` | `563` | Usenet port |
| `USENET_SSL` | `true` | Use SSL for usenet (`true` / `false`) |
| `USENET_MAX_CONN` | `100` | Max usenet connections |
| `WEBUI_PORT` | `3000` | Port for the web UI |
| `PUID` | auto-detected | User ID for file permissions |
| `PGID` | auto-detected | Group ID for file permissions |
| `TZ` | system timezone | Container timezone |
| `NZBDAV_VERSION` | `0.6.4` | NzbDav Docker image tag |
| `RCLONE_VERSION` | `1.74.3` | Rclone Docker image tag |
| `INSTALL_DIR` | `/DATA/AppData/nzbdav` | Install and config directory |

### Skip usenet (configure later in the UI)

Omit `USENET_HOST`, `USENET_USER`, and `USENET_PASS`. The stack still installs; add your provider under **Settings → Usenet** in the web UI.

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  bash
```

### Change the web UI port

```bash
WEBUI_PORT=3001 curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

## Interactive install

If you prefer prompts instead of environment variables:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash
```

## What gets installed

| Path | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/docker-compose.yml` | Docker Compose stack |
| `/DATA/AppData/nzbdav/.env` | Container environment variables |
| `/DATA/AppData/nzbdav/rclone.conf` | Rclone WebDAV credentials |
| `/DATA/AppData/nzbdav/config/` | NzbDav database and settings |
| `/DATA/AppData/nzbdav/credentials.txt` | Login summary (chmod 600) |
| `/DATA/remote/nzbdav/` | Rclone mount point on the host |

Two containers are created:

| Container | Purpose |
|---|---|
| `nzbdav` | Web UI, WebDAV server, SABnzbd-compatible API |
| `nzbdav_rclone` | Mounts WebDAV to `/DATA/remote/nzbdav` |

## After install

### Verify

```bash
docker ps | grep nzbdav
ls /DATA/remote/nzbdav
cat /DATA/AppData/nzbdav/credentials.txt
```

### Radarr / Sonarr

| Setting | Value |
|---|---|
| Download client | SABnzbd |
| Host | `nzbdav` (same Docker network) or your server IP |
| Port | `3000` (or your `WEBUI_PORT`) |
| API key | NzbDav → **Settings → SABnzbd** |
| Import path | `/DATA/remote/nzbdav/completed-symlinks/...` |

Full Radarr/Sonarr/Plex workflow: [docs/setup-guide.md](../docs/setup-guide.md)

## Manage the stack

```bash
cd /DATA/AppData/nzbdav

# View logs
docker compose -p nzbdav logs -f

# Restart
docker compose -p nzbdav restart

# Stop
docker compose -p nzbdav down
```

## Uninstall

Stop containers but keep config:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash -s -- --uninstall
```

Remove everything including config and credentials:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash -s -- --uninstall --purge
```

## Reinstall

Safe to run the install command again. The script removes old containers and recreates the stack.

If a previous attempt left a broken compose file:

```bash
sudo rm -f /DATA/AppData/nzbdav/docker-compose.yml
```

Then run the install command again.

## Troubleshooting

| Issue | What to do |
|---|---|
| `command.1 must be a string` | You have an old compose file. Delete it and re-run the latest script. |
| `PUID/PGID: 0/0` | Re-run with the latest script — it auto-detects your user. |
| Rclone keeps restarting | `docker logs nzbdav_rclone` — usually a bad `rclone.conf` or WebDAV password mismatch. |
| NzbDav won't start | `docker logs nzbdav` — check if port 3000 is already in use. |
| Mount folder empty | Wait 30 seconds, then `docker restart nzbdav_rclone`. |
| Radarr/Sonarr can't connect | Use server IP from another machine; use hostname `nzbdav` from containers on the same network. |

## Requirements

- Ubuntu server with [CasaOS](https://casaos.io/) (or Docker + `/DATA` directory)
- Docker and Docker Compose
- Root access (`sudo`)
- Usenet provider account (can be added later via the UI)
