# Installing NzbDav on ZimaOS

[ZimaOS](https://www.zimaspace.com/) uses the same `/DATA` layout as CasaOS. The **recommended** install is the one-command script (it creates both containers, `rclone.conf`, and configures WebDAV automatically).

For manual installs, use **SSH + `docker compose`** if possible. ZimaOS Compose Toolbox can strip volume flags like `:rshared`, which this stack needs for the Rclone mount.

## Option 1 — One-command install (recommended)

SSH into your ZimaOS box and run:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

When it finishes:

| Item | Location |
|---|---|
| Web UI | `http://<zimaos-ip>:3000` |
| Credentials | `/DATA/AppData/nzbdav/credentials.txt` |
| Rclone mount | `/DATA/remote/nzbdav` |
| Compose stack | `/DATA/AppData/nzbdav/` |

Full variable reference: [scripts/README.md](../scripts/README.md)

## Option 2 — Manual compose (exact files)

Use this if you want to paste a compose file yourself or manage the stack in Compose Toolbox.

### Step 1 — Create folders

```bash
sudo mkdir -p /DATA/AppData/nzbdav/config /DATA/remote/nzbdav
```

### Step 2 — Create `.env`

Save as `/DATA/AppData/nzbdav/.env`:

```bash
PUID=1000
PGID=1000
TZ=America/New_York
WEBUI_PORT=3000
```

Adjust `PUID`/`PGID` to match your ZimaOS user (`id yourusername`). Change `TZ` to your timezone.

### Step 3 — Create `rclone.conf`

1. Open NzbDav in the browser and set a **WebDAV username/password** under **Settings → WebDAV**.
2. Obscure the WebDAV password:

```bash
docker run --rm rclone/rclone:1.74.3 obscure 'YOUR_WEBDAV_PASSWORD'
```

3. Save `/DATA/AppData/nzbdav/rclone.conf` (replace user and obscured pass):

```ini
[nzbdav]
type = webdav
url = http://nzbdav:3000/
vendor = other
user = admin
pass = PASTE_OBSCURED_PASSWORD_HERE
```

```bash
sudo chmod 600 /DATA/AppData/nzbdav/rclone.conf
```

### Step 4 — Create `docker-compose.yml`

Save as `/DATA/AppData/nzbdav/docker-compose.yml`:

```yaml
name: nzbdav
services:
  nzbdav:
    container_name: nzbdav
    image: nzbdav/nzbdav:0.6.4
    restart: unless-stopped
    env_file:
      - .env
    environment:
      PUID: ${PUID}
      PGID: ${PGID}
      TZ: ${TZ}
    ports:
      - "${WEBUI_PORT:-3000}:3000"
    volumes:
      - /DATA/AppData/nzbdav/config:/config
      - /DATA/remote:/mnt/remote:rshared
    healthcheck:
      test: curl -f http://localhost:3000/health || exit 1
      interval: 30s
      retries: 5
      start_period: 60s
      timeout: 10s
    networks:
      - nzbdav

  nzbdav_rclone:
    container_name: nzbdav_rclone
    image: rclone/rclone:1.74.3
    restart: unless-stopped
    depends_on:
      - nzbdav
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    devices:
      - /dev/fuse:/dev/fuse:rwm
    env_file:
      - .env
    environment:
      PUID: ${PUID}
      PGID: ${PGID}
      TZ: ${TZ}
    volumes:
      - /DATA/remote:/mnt/remote:rshared
      - /DATA/AppData/nzbdav/rclone.conf:/config/rclone/rclone.conf
    command: >-
      mount nzbdav: /mnt/remote/nzbdav
      --allow-other
      --links
      --use-cookies
      --vfs-cache-mode=full
      --vfs-cache-max-size=20G
      --vfs-cache-max-age=24h
      --buffer-size=0M
      --vfs-read-ahead=512M
      --dir-cache-time=20s
      --uid=1000
      --gid=1000
    networks:
      - nzbdav

networks:
  nzbdav:
    driver: bridge
```

> **Important:** Replace `--uid=1000` and `--gid=1000` in the rclone `command` with your actual `PUID`/`PGID` from `.env`. The install script does this automatically.

> **Rclone command format:** Use the folded string (`command: >-`) shown above. ZimaOS/CasaOS validators reject YAML array commands when the mount path contains `nzbdav:`.

### Step 5 — Start the stack

**Preferred (preserves `:rshared`):**

```bash
cd /DATA/AppData/nzbdav
sudo docker compose up -d
```

**Alternative — ZimaOS Compose Toolbox:**

1. Open **Zima Apps → Compose Toolbox**
2. Click **Import** and paste the `docker-compose.yml` above
3. Set the stack path to `/DATA/AppData/nzbdav`
4. Deploy

If the mount is empty after deploy, the UI may have dropped `:rshared`. Re-deploy from SSH instead.

### Step 6 — NzbDav settings

In the Web UI (**Settings**):

| Setting | Value |
|---|---|
| WebDAV user / pass | Same as in `rclone.conf` |
| Rclone mount dir | `/mnt/remote/nzbdav` |
| Import strategy | Symlinks |

Restart the rclone container after changing WebDAV credentials:

```bash
docker restart nzbdav_rclone
```

## Radarr / Sonarr on ZimaOS

Install Radarr/Sonarr from the ZimaOS App Store or Compose Toolbox. Point them at the rclone mount:

| Setting | Value |
|---|---|
| Download client | SABnzbd |
| Host | `nzbdav` (if on same Docker network) or your ZimaOS IP |
| Port | `3000` |
| API key | NzbDav → **Settings → SABnzbd** |
| Category (Radarr) | `movies` |
| Category (Sonarr) | `tv` |
| Completed download folder | `/DATA/remote/nzbdav/completed-symlinks/movies` (Radarr) or `.../tv` (Sonarr) |

If Radarr/Sonarr run in Docker, add a **Remote Path Mapping**:

| Remote path | Local path |
|---|---|
| `/mnt/remote/nzbdav` | `/DATA/remote/nzbdav` |

To put Radarr on the same network as NzbDav, connect the Radarr container to the `nzbdav` network (or reinstall Radarr with an extra network in compose).

Full workflow: [setup-guide.md](setup-guide.md)

## Verify

```bash
docker ps | grep nzbdav
docker logs nzbdav_rclone --tail 20
ls -la /DATA/remote/nzbdav
```

You should see folders such as `content` and (after downloads complete) `completed-symlinks`.

## Manage / uninstall

```bash
cd /DATA/AppData/nzbdav
docker compose logs -f
docker compose restart
docker compose down
```

Uninstall via script:

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash -s -- --uninstall
```

Add `--purge` to delete config and credentials.

## Troubleshooting

| Issue | Fix |
|---|---|
| Only `nzbdav` container, no rclone | Your compose is missing `nzbdav_rclone`. Use the full file above or re-run the install script. |
| `command.1 must be a string` | Use `command: >-` (folded string), not a YAML list. |
| Mount empty | `docker restart nzbdav_rclone`; confirm WebDAV password matches `rclone.conf`. |
| `:rshared` missing | Deploy with `docker compose` over SSH, not the Web UI volume editor. |
| Radarr sees only `content/` | Set category to `movies`/`tv`; check `completed-symlinks` after a finished download. |

## See also

- [CasaOS / script installer README](../scripts/README.md)
- [Unraid installer](../scripts/README-unraid.md)
- [Compose file for App Store import](../Apps/NzbDav/docker-compose.yml)
