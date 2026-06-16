# NzbDav Unraid Installer

One-command installer for **NzbDav + Rclone** on [Unraid](https://unraid.net/).

The script installs both containers, generates `rclone.conf`, creates your admin account, configures WebDAV and usenet, and mounts the WebDAV share under your appdata folder. No Docker Manager template editing required.

Run from the **Unraid terminal** (Tools → Terminal, or SSH).

## Non-interactive install (recommended)

```bash
NZBDAV_ADMIN_PASS='your-admin-password' \
NZBDAV_WEBDAV_PASS='your-webdav-password' \
USENET_HOST='news.newshosting.com' \
USENET_USER='your-usenet-user' \
USENET_PASS='your-usenet-pass' \
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh)
```

Replace the placeholder values with your real credentials.

When it finishes:

- Web UI: `http://<unraid-ip>:3000`
- Credentials: `/mnt/user/appdata/nzbdav/credentials.txt`
- Rclone mount: `/mnt/user/appdata/nzbdav/mount/nzbdav`

### Example

```bash
NZBDAV_ADMIN_PASS='MySecureAdmin123' \
NZBDAV_WEBDAV_PASS='MySecureWebdav123' \
USENET_HOST='news.newshosting.com' \
USENET_USER='nh12345' \
USENET_PASS='my-usenet-password' \
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh)
```

## Required environment variables

| Variable | Description |
|---|---|
| `NZBDAV_ADMIN_PASS` | Password for the NzbDav web UI login |
| `NZBDAV_WEBDAV_PASS` | Password for WebDAV / Rclone access |
| `USENET_HOST` | Usenet provider hostname |
| `USENET_USER` | Usenet username |
| `USENET_PASS` | Usenet password |

## Optional environment variables

| Variable | Default | Description |
|---|---|---|
| `NZBDAV_ADMIN_USER` | `admin` | Web UI login username |
| `NZBDAV_WEBDAV_USER` | `admin` | WebDAV username |
| `USENET_PORT` | `563` | Usenet port |
| `USENET_SSL` | `true` | Use SSL (`true` / `false`) |
| `USENET_MAX_CONN` | `100` | Max usenet connections |
| `WEBUI_PORT` | `3000` | Web UI port |
| `PUID` | `99` | Unraid `nobody` user |
| `PGID` | `100` | Unraid `users` group |
| `TZ` | system / `America/New_York` | Container timezone |
| `INSTALL_DIR` | `/mnt/user/appdata/nzbdav` | Appdata install path |
| `MOUNT_HOST_PATH` | `/mnt/user/appdata/nzbdav/mount` | Host path for rclone mount |
| `NZBDAV_EXTRA_NETWORK` | _(none)_ | Existing Docker network for Radarr/Sonarr (e.g. `proxynet`) |
| `UNRAID_IP` | auto-detected | Server IP for the install summary |
| `NZBDAV_VERSION` | `0.6.4` | NzbDav image tag |
| `RCLONE_VERSION` | `1.74.3` | Rclone image tag |

### Skip usenet (configure later)

```bash
NZBDAV_ADMIN_PASS='your-admin-password' \
NZBDAV_WEBDAV_PASS='your-webdav-password' \
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh)
```

### Connect to Radarr/Sonarr Docker network

If your *arr containers share a custom network, attach NzbDav to it so they can reach `nzbdav` by hostname:

```bash
NZBDAV_EXTRA_NETWORK='proxynet' \
NZBDAV_ADMIN_PASS='your-admin-password' \
NZBDAV_WEBDAV_PASS='your-webdav-password' \
USENET_HOST='news.newshosting.com' \
USENET_USER='your-usenet-user' \
USENET_PASS='your-usenet-pass' \
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh)
```

Replace `proxynet` with your actual network name (`docker network ls` to list).

## Interactive install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh)
```

## What gets installed

| Path | Purpose |
|---|---|
| `/mnt/user/appdata/nzbdav/docker-compose.yml` | Docker Compose stack |
| `/mnt/user/appdata/nzbdav/.env` | Container environment |
| `/mnt/user/appdata/nzbdav/rclone.conf` | Rclone WebDAV credentials |
| `/mnt/user/appdata/nzbdav/config/` | NzbDav database and settings |
| `/mnt/user/appdata/nzbdav/credentials.txt` | Login summary |
| `/mnt/user/appdata/nzbdav/mount/nzbdav/` | Rclone mount (streams, symlinks) |

| Container | Purpose |
|---|---|
| `nzbdav` | Web UI, WebDAV, SABnzbd-compatible API |
| `nzbdav_rclone` | FUSE mount to appdata |

Containers appear in the Unraid **Docker** tab. They are not installed via Community Applications, but work alongside your existing containers.

## After install

### Verify

```bash
docker ps | grep nzbdav
ls /mnt/user/appdata/nzbdav/mount/nzbdav
cat /mnt/user/appdata/nzbdav/credentials.txt
```

### Radarr / Sonarr on Unraid

| Setting | Value |
|---|---|
| Download client | SABnzbd |
| Host | Your Unraid IP, or `nzbdav` if on `NZBDAV_EXTRA_NETWORK` |
| Port | `3000` |
| API key | NzbDav → **Settings → SABnzbd** |
| Root folder / import | `/mnt/user/appdata/nzbdav/mount/nzbdav/completed-symlinks/...` |

When adding paths in Radarr/Sonarr, map the container path if the *arr container mounts appdata, or use the host path above if it has access to `/mnt/user`.

Full workflow: [docs/setup-guide.md](../docs/setup-guide.md)

## Manage the stack

```bash
cd /mnt/user/appdata/nzbdav

docker compose -p nzbdav logs -f
docker compose -p nzbdav restart
docker compose -p nzbdav down
```

## Uninstall

Keep config:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh) --uninstall
```

Remove everything:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-unraid.sh) --uninstall --purge
```

## Reinstall

Safe to run the install command again. The script recreates containers from scratch.

## Troubleshooting

| Issue | What to do |
|---|---|
| `/mnt/user not found` | Run on Unraid, not a generic Linux VM without user shares |
| Docker Compose not found | Update to Unraid 6.12+ or install compose plugin |
| Rclone keeps restarting | `docker logs nzbdav_rclone` — check WebDAV password |
| Radarr can't reach NzbDav | Use Unraid server IP, or set `NZBDAV_EXTRA_NETWORK` |
| Permission errors | Keep `PUID=99` and `PGID=100` (Unraid defaults) |
| Port 3000 in use | Set `WEBUI_PORT=3001` before running |

## Requirements

- Unraid 6.12+ recommended (Docker Compose support)
- Docker enabled in Unraid Settings
- Usenet provider account (can be added later in the UI)

## See also

- [CasaOS installer](README.md)
- [Full NzbDav setup guide](../docs/setup-guide.md)
