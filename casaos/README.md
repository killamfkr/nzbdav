# NzbDav on CasaOS

## One-command install

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash
```

See [docs/casaos-install.md](../docs/casaos-install.md) for non-interactive options and troubleshooting.

## Manual compose import

Only use this if you cannot run the install script. You must still create `rclone.conf` yourself.

1. **App Store** → **Install a customized app** → **Import**
2. Paste: `https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml`
