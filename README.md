# Bong Wallpaper

Menu bar macOS app that fetches wallpapers from Bing and applies them locally.

## Run

```bash
swift build
swift run BongWallpaper
```

## MVP behavior

- Uses Bing public endpoint directly (`global.bing.com/HPImageArchive.aspx`).
- Caches downloaded wallpapers in:
  - `~/Library/Application Support/BongWallpaper/Wallpapers/`
  - `~/Library/Application Support/BongWallpaper/metadata.json`
- Supports actions from menu bar:
  - Previous
  - Next
  - Download
  - Rotate Daily

## Bundled fallback wallpapers

Add image files (`jpg`, `jpeg`, `png`, `heic`, `webp`) to:

`Sources/BongWallpaper/Resources/BundledWallpapers/`

These files are used when cache is empty or network is unavailable.
