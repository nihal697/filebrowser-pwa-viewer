# Results Viewer PWA

A tiny, **installable** web app (Android → Add to Home Screen) that turns any
folder of backtest/analysis results (CSVs, PNGs, .txt/.md/.json) into a clean
mobile-first viewer. **No server code, no auth, works offline** after first load.

Each viewer is a **self-contained static bundle**: copy your result files into it
and host the folder anywhere (Caddy/nginx/GitHub Pages/Cloudflare Pages).

## Quick start (your own files)

```bash
git clone https://github.com/nihal697/filebrowser-pwa-viewer
cd filebrowser-pwa-viewer
./build.sh --src /path/to/my/results --out /tmp/my-pwa \
  --title "My Strategy — Results" --subtitle "NIFTY 4H · 2008–2026"
# serve /tmp/my-pwa with any static host, open index.html, install on phone
```

`build.sh` copies everything under `--src` into `data/`, writes
`data/manifest.json` (auto-discovered file list), and stamps the title into
`config.js` + PWA `manifest.json`. The app renders:

- **Reports** — top-level `.md`/`.txt` inline (collapsible), rest grouped after
- **Charts** — every image, grouped by folder, lazy-loaded
- **Data files** — every `.csv`/`.json` with open/download links
- **All files** — searchable full listing

## Hosting examples

**Caddy** (same box):
```
handle_path /sweep/* {
    root * /var/www/sweep
    file_server
}
```

**Any static host**: upload the output folder as-is. All paths are relative,
so it works from any sub-path.

## Notes

- Files over ~400 KB are link-only (no inline preview) — configurable in `config.js`.
- The service worker caches the shell + viewed files for offline use.
- Nothing is uploaded anywhere; the bundle only reads its own `data/` folder.

## License

MIT
