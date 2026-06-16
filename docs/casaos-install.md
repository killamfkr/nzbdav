# Installing NzbDav on CasaOS

## One-command install (recommended)

SSH into your server and run:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash
```

The script will:

1. Install **NzbDav** and **Rclone** together
2. Prompt for admin password, WebDAV password, and usenet details
3. Generate `rclone.conf` automatically
4. Create your admin account and apply settings
5. Mount WebDAV at `/DATA/remote/nzbdav`

When it finishes, open `http://<your-server-ip>:3000` and log in. Credentials are saved to `/DATA/AppData/nzbdav/credentials.txt`.

### Non-interactive install

Set everything via environment variables:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash -s -- --uninstall
```

Add `--purge` to also delete config and credentials.

---

## Manual install (compose paste)

If you prefer CasaOS's compose importer instead of the script:

1. **App Store** → **Install a customized app** → **Import**
2. Paste: `https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml`
3. You still need to manually create `/DATA/AppData/nzbdav/rclone.conf` — see below

The install script is strongly recommended because it handles rclone config and API setup for you.

---

## What the script installs

| Path | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/` | Compose files, `.env`, `rclone.conf`, credentials |
| `/DATA/AppData/nzbdav/config` | NzbDav database and settings |
| `/DATA/remote/nzbdav` | Rclone mount (symlinks, streams) |

## Radarr / Sonarr / Plex

- **Download client:** SABnzbd → host `nzbdav` (or server IP), port `3000`
- **API key:** NzbDav → Settings → SABnzbd
- **Import path:** `/DATA/remote/nzbdav/completed-symlinks/...`
- Full guide: [setup-guide.md](setup-guide.md)

## Troubleshooting

| Issue | Solution |
|---|---|
| Script says Docker not running | Run with `sudo bash` |
| Rclone keeps restarting | `docker logs nzbdav_rclone` — usually bad `rclone.conf` |
| Port 3000 in use | `WEBUI_PORT=3001 curl ... \| sudo bash` |
| Re-run install | Safe to run again; script recreates containers |

## Manual rclone.conf (only if not using the script)

```bash
docker run --rm rclone/rclone:1.74.3 obscure "YOUR_WEBDAV_PASSWORD"

mkdir -p /DATA/AppData/nzbdav
nano /DATA/AppData/nzbdav/rclone.conf
```

```ini
[nzbdav]
type = webdav
url = http://nzbdav:3000/
vendor = other
user = YOUR_WEBDAV_USERNAME
pass = PASTE_OBSCURED_PASSWORD_HERE
```

Then restart: `docker restart nzbdav_rclone`
