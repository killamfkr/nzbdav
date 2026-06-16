# Installing NzbDav on CasaOS

This guide installs NzbDav **with the Rclone sidecar** on an Ubuntu server running [CasaOS](https://casaos.io/).

## Prerequisites

- Ubuntu server with CasaOS installed
- A usenet provider account

## Install via Compose import

### Step 1: Open the custom app installer

1. Log in to your CasaOS dashboard (`http://<your-server-ip>`).
2. Open **App Store**.
3. Click **Install a customized app**.
4. Click **Import** (top-right of the compose editor).

### Step 2: Paste the compose file

Copy the compose file from this URL and paste it into the text box:

```
https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml
```

Click **Submit** / **OK**, then **Install**.

This installs two containers:
- **nzbdav** — WebDAV server and web UI
- **nzbdav_rclone** — mounts the WebDAV share to your filesystem

### Step 3: Configure NzbDav

1. Open NzbDav at `http://<your-server-ip>:3000`.
2. Create your **admin account**.
3. **Settings → Usenet** — enter your usenet provider details.
4. **Settings → WebDAV** — set a WebDAV **username** and **password** (remember these).

### Step 4: Configure Rclone

Rclone needs a config file before it can mount. SSH into your server (or use CasaOS terminal):

**1. Generate an obscured password** (replace with your WebDAV password from step 3):

```bash
docker run --rm rclone/rclone:1.74.3 obscure "YOUR_WEBDAV_PASSWORD"
```

Copy the output (starts with something like `obscure-token...`).

**2. Create the config file:**

```bash
mkdir -p /DATA/AppData/nzbdav
nano /DATA/AppData/nzbdav/rclone.conf
```

Paste this and replace the placeholders:

```ini
[nzbdav]
type = webdav
url = http://nzbdav:3000/
vendor = other
user = YOUR_WEBDAV_USERNAME
pass = PASTE_OBSCURED_PASSWORD_HERE
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X` in nano).

**3. Create the mount directory:**

```bash
mkdir -p /DATA/remote/nzbdav
```

**4. Restart the app** from CasaOS (or restart just the rclone container):

```bash
docker restart nzbdav_rclone
```

**5. Verify the mount:**

```bash
ls -la /DATA/remote/nzbdav
```

You should see folders like `.ids`, `completed-symlinks`, `content`, and `nzbs`.

### Step 5: Point NzbDav at the mount

In NzbDav **Settings → SABnzbd**:

- **Rclone Mount Directory:** `/mnt/remote/nzbdav`

## Data locations

| Path on server | Purpose |
|---|---|
| `/DATA/AppData/nzbdav/config` | NzbDav settings and database |
| `/DATA/AppData/nzbdav/rclone.conf` | Rclone WebDAV credentials |
| `/DATA/remote/nzbdav` | Mounted WebDAV files (symlinks, streams) |

## Radarr / Sonarr / Plex

- **Download client:** SABnzbd → host `nzbdav`, port `3000`, API key from NzbDav Settings → SABnzbd
- **Library import path:** `/DATA/remote/nzbdav/completed-symlinks/...` (or your symlink folder)
- Full workflow: [comprehensive setup guide](setup-guide.md)

## Updating

1. Open the NzbDav app in CasaOS → **Settings** → **Compose**.
2. Update image tags if needed (`nzbdav/nzbdav:0.6.4`, `rclone/rclone:1.74.3`).
3. Save and restart.

## Troubleshooting

| Issue | Solution |
|---|---|
| `nzbdav_rclone` keeps restarting | `rclone.conf` is missing or wrong. Check WebDAV username and obscured password. |
| Mount folder is empty | Ensure NzbDav is healthy first. Run `docker logs nzbdav_rclone`. |
| Permission denied on mount | Match `--uid` / `--gid` in the compose file to your user (`id` over SSH). Default is `1000`. |
| Radarr/Sonarr can't see files | Point library imports at `/DATA/remote/nzbdav/completed-symlinks`. |
| Port 3000 in use | Change `published: "3000"` and `port_map: "3000"` to another port. |

## Already installed without Rclone?

If you installed an older compose file with only the `nzbdav` service:

1. Open the app in CasaOS → **Settings** → **Compose**.
2. Replace the entire compose file with the current version from the URL above.
3. Follow **Step 4** to create `rclone.conf`.
4. Save and restart.
