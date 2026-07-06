# Installing NzbDav on CasaOS

Also works on **[ZimaOS](../docs/zimaos-install.md)** (same `/DATA` paths and install script).

See **[scripts/README.md](../scripts/README.md)** for the full install guide, including the non-interactive one-liner.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

## Also in this guide

The [scripts README](../scripts/README.md) covers:

- All environment variables
- Optional settings (port, usenet skip, etc.)
- Uninstall and reinstall
- Radarr / Sonarr integration
- Troubleshooting

For the full Radarr/Sonarr/Plex infinite-library workflow, see [setup-guide.md](setup-guide.md).
