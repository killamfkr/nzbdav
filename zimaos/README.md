# NzbDav on ZimaOS

**Recommended — one command:**

```bash
curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo \
  NZBDAV_ADMIN_PASS='your-admin-password' \
  NZBDAV_WEBDAV_PASS='your-webdav-password' \
  USENET_HOST='news.newshosting.com' \
  USENET_USER='your-usenet-user' \
  USENET_PASS='your-usenet-pass' \
  bash
```

**Manual compose + step-by-step setup:** [docs/zimaos-install.md](../docs/zimaos-install.md)

Compose files:

- [Apps/NzbDav/docker-compose.zimaos.yml](../Apps/NzbDav/docker-compose.zimaos.yml)
- [Apps/NzbDav/.env.zimaos.example](../Apps/NzbDav/.env.zimaos.example)
- [Apps/NzbDav/rclone.conf.example](../Apps/NzbDav/rclone.conf.example)
