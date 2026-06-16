# NzbDav on CasaOS

Install NzbDav on CasaOS by importing a Docker Compose file.

## Quick install

1. **App Store** → **Install a customized app**
2. Click **Import** (top-right of the compose editor)
3. Paste the contents of:

   ```
   https://raw.githubusercontent.com/killamfkr/nzbdav/main/Apps/NzbDav/docker-compose.yml
   ```

4. Click **Install**

Full instructions: [docs/casaos-install.md](../docs/casaos-install.md)

## Files

```
Apps/NzbDav/
├── docker-compose.yml   # Paste this into CasaOS
├── icon.png
└── screenshot-1.png
```

## Updating the image version

When a new release is published, update the image tag in [`Apps/NzbDav/docker-compose.yml`](../Apps/NzbDav/docker-compose.yml) and the `version` field in the `x-casaos` block.
