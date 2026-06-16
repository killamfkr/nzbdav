# NzbDav CasaOS App Store

This directory contains a [CasaOS](https://casaos.io/) app definition for one-click installation of NzbDav on Ubuntu servers running CasaOS.

## Quick install on CasaOS

1. Open **App Store** in the CasaOS web UI.
2. Click the **⋮** menu (top right) → **Import a Zip or URL**.
3. Paste this URL:

   ```
   https://github.com/killamfkr/nzbdav/archive/refs/heads/main.zip
   ```

4. Find **NzbDav** in the store and click **Install**.
5. After install, open the app and complete first-time setup (admin account, usenet provider, WebDAV credentials).

For step-by-step instructions and Radarr/Sonarr integration, see [docs/casaos-install.md](../docs/casaos-install.md).

## Directory layout

```
Apps/
└── NzbDav/
    ├── docker-compose.yml   # CasaOS compose app with x-casaos metadata
    ├── icon.png             # 192×192 app icon
    └── screenshot-1.png     # 1280×720 screenshot
recommend-list.json          # Shows NzbDav in recommended apps (repo root)
```

## Updating the image version

When a new NzbDav release is published, update the image tag in [`Apps/NzbDav/docker-compose.yml`](../Apps/NzbDav/docker-compose.yml):

```yaml
image: nzbdav/nzbdav:0.6.4
```

Also update the `version` field in the `x-casaos` block at the bottom of the same file.

## Submitting to the official CasaOS App Store

To list NzbDav in the [official CasaOS App Store](https://github.com/IceWhaleTech/CasaOS-AppStore), open a pull request there with the contents of `Apps/NzbDav/` following their [contributing guide](https://github.com/IceWhaleTech/CasaOS-AppStore/blob/main/CONTRIBUTING.md).
