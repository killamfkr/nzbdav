# NzbDav ZimaOS Installer

One-command installer for **NzbDav + Rclone** on [ZimaOS](https://www.zimaspace.com/zimaos).

The script installs both containers, prepares the host for **FUSE** (`/dev/fuse`, `user_allow_other`), generates `rclone.conf`, creates your admin account, configures WebDAV and usenet, and mounts the WebDAV share at `/DATA/remote/nzbdav`.

Run from **Settings → Developer → Web Terminal** or SSH (enable SSH under Developer mode first).

## Non-interactive install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

When it finishes:

- Web UI: `http://<zimaos-ip>:3000`
- Credentials: `/DATA/AppData/nzbdav/credentials.txt`
- Rclone mount: `/DATA/remote/nzbdav`

### Example

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo \
  NZBDAV_ADMIN_PASS='MySecureAdmin123' \
  NZBDAV_WEBDAV_PASS='MySecureWebdav123' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='nh12345' \
  USENET_PASS='my-usenet-password' \
  bash
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
| `PUID` / `PGID` | auto-detected | File ownership on the rclone mount |
| `TZ` | system timezone | Container timezone |
| `INSTALL_DIR` | `/DATA/AppData/nzbdav` | Config and compose directory |
| `REMOTE_ROOT` | `/DATA/remote` | Host path shared with rclone (`:rshared`) |
| `NZBDAV_EXTRA_NETWORK` | _(none)_ | Existing Docker network for Radarr/Sonarr |
| `NZBDAV_VERSION` | `0.6.4` | NzbDav image tag |
| `RCLONE_VERSION` | `1.74.3` | Rclone image tag |

### Skip usenet (configure later)

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  bash
```

### Connect to Radarr/Sonarr Docker network

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo \
  NZBDAV_EXTRA_NETWORK='your_network_name' \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

Use `docker network ls` on ZimaOS to find the network your *arr apps use.

## Interactive install

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo bash
```

## What gets installed

| Path | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/docker-compose.yml` | Stack definition |
| `/DATA/AppData/nzbdav/.env` | Container environment |
| `/DATA/AppData/nzbdav/rclone.conf` | Rclone WebDAV credentials |
| `/DATA/AppData/nzbdav/config/` | NzbDav database and settings |
| `/DATA/remote/nzbdav/` | Rclone FUSE mount (streams, symlinks) |
| `/var/lib/casaos/apps/nzbdav/` | Copy of compose for ZimaOS Apps UI |

| Container | Role |
|---|---|
| `nzbdav` | Web UI, WebDAV, usenet |
| `nzbdav_rclone` | FUSE mount to `/DATA/remote/nzbdav` |

## FUSE on ZimaOS

ZimaOS does not ship `apt`; rclone runs **inside Docker** with:

- `SYS_ADMIN` capability
- `/dev/fuse` passed through
- `apparmor:unconfined` (same pattern as the CasaOS app template)

The installer additionally:

1. Loads the `fuse` kernel module (`modprobe fuse`)
2. Ensures `/dev/fuse` exists
3. Enables `user_allow_other` in `/etc/fuse.conf` (required for `--allow-other`)
4. Sets **shared mount propagation** on `/DATA/remote` so other containers can see the mount

If the mount fails after install:

```bash
sudo modprobe fuse
grep user_allow_other /etc/fuse.conf
docker logs nzbdav_rclone
docker restart nzbdav_rclone
```

To unmount manually:

```bash
sudo fusermount -uz /DATA/remote/nzbdav
```

## After install

1. Open the Web UI and confirm **Settings → SABnzbd** / **Rclone** paths.
2. In Radarr/Sonarr, set the download client to SABnzbd at your ZimaOS IP, port `3000`.
3. For library imports, use paths under `/DATA/remote/nzbdav/...` (or map that folder into other apps as `/DATA/remote/nzbdav` → container path).

Prefer `/DATA/Media` and `/DATA/AppData/...` in app volume mappings—not raw `/mnt/<uuid>` paths—so storage survives drive changes ([ZimaOS docker paths](https://www.zimaspace.com/docs/zimaos/docker-app-paths)).

## Uninstall

Keep config:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo bash -s -- --uninstall
```

Remove everything:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-zimaos.sh | sudo bash -s -- --uninstall --purge
```

## Troubleshooting

| Symptom | What to try |
|---|---|
| Rclone keeps restarting | `docker logs nzbdav_rclone` — WebDAV password or FUSE |
| Mount folder empty | Wait 30s, then `docker restart nzbdav_rclone` |
| `allow other` / permission errors | Confirm `user_allow_other` in `/etc/fuse.conf` |
| Other apps cannot see mount | Map `/DATA/remote/nzbdav` with `:shared` / use same host path |
| `/dev/fuse` missing | `sudo modprobe fuse` and reboot if needed |

## See also

- [CasaOS installer](README.md) (same `/DATA` layout on Ubuntu CasaOS)
- [Unraid installer](README-unraid.md)
- [Setup guide](../docs/setup-guide.md)
