#!/usr/bin/env bash
set -euo pipefail

emsdk_version=6.0.11
emsdk_dir="${EMSDK_DIR:-/tmp/emsdk}"
emsdk_download_cache="$PWD/.vercel/cache/emsdk-downloads"

if ! command -v emcc >/dev/null 2>&1; then
  if [ ! -d "$emsdk_dir" ]; then
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$emsdk_dir"
  fi
  mkdir -p "$emsdk_download_cache"
  if [ ! -L "$emsdk_dir/downloads" ]; then
    rm -rf "$emsdk_dir/downloads"
    ln -s "$emsdk_download_cache" "$emsdk_dir/downloads"
  fi
  "$emsdk_dir/emsdk" install "$emsdk_version"
  "$emsdk_dir/emsdk" activate "$emsdk_version"
  source "$emsdk_dir/emsdk_env.sh"
fi

export EM_CACHE="${EM_CACHE:-$PWD/.vercel/cache/emscripten}"
mkdir -p "$EM_CACHE"
make wasm
rm -rf .vercel/output
mkdir -p .vercel/output/static/wads
cp demo/doom.html .vercel/output/static/index.html
cp demo/doom.js demo/doom.wasm demo/doom.data .vercel/output/static/
cp demo/wads/*.wad .vercel/output/static/wads/
cp favicon.svg .vercel/output/static/

site_url="${SITE_URL:-}"
if [ -z "$site_url" ] && [ -n "${VERCEL_PROJECT_PRODUCTION_URL:-}" ]; then
  site_url="https://${VERCEL_PROJECT_PRODUCTION_URL#https://}"
fi
site_url="${site_url%/}"

if [ -n "$site_url" ]; then
  case "$site_url" in
    https://*|http://*) ;;
    *) echo "SITE_URL must start with https:// or http://" >&2; exit 1 ;;
  esac
  export SITE_URL="$site_url"
  python3 - <<'PY'
import html
import json
import os
import re
from pathlib import Path
from xml.sax.saxutils import escape

site_url = os.environ["SITE_URL"]
index = Path(".vercel/output/static/index.html")
static = Path(".vercel/output/static")
metadata = f'''<link rel="canonical" href="{html.escape(site_url + "/", quote=True)}">
  <meta property="og:url" content="{html.escape(site_url + "/", quote=True)}">
  <script type="application/ld+json">{{
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "Doom Generic",
    "url": "{escape(site_url + "/")}",
    "description": "Play a free Doom-style first-person shooter online in your browser, powered by WebAssembly and Freedoom.",
    "applicationCategory": "GameApplication",
    "operatingSystem": "Any",
    "browserRequirements": "Requires JavaScript and WebAssembly",
    "isAccessibleForFree": true
  }}</script>'''
page = index.read_text()
index.write_text(re.sub(r'<meta name=["\']?vercel-seo-marker["\']?>', metadata, page))
static.joinpath("sitemap.xml").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    f'<url><loc>{escape(site_url)}/</loc></url></urlset>\n'
)
PY
  if [ "${VERCEL_ENV:-}" = preview ]; then
    printf 'User-agent: *\nDisallow: /\n' > .vercel/output/static/robots.txt
  else
    printf 'User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' "$site_url" > .vercel/output/static/robots.txt
  fi
else
  echo "No production URL found; set SITE_URL to generate canonical metadata and sitemap." >&2
  printf 'User-agent: *\nAllow: /\n' > .vercel/output/static/robots.txt
fi

python3 - <<'PY'
import json
from pathlib import Path

config = {
    "version": 3,
    "cache": [
        ".vercel/cache/emsdk-downloads/**",
        ".vercel/cache/emscripten/**",
        "doomgeneric/freedoom-*.zip",
        "doomgeneric/freedm-*.zip",
        "doomgeneric/dgguspat-*.zip",
        "doomgeneric/freedoom*.wad",
        "doomgeneric/freedm.wad",
        "doomgeneric/dgguspat/**",
        "doomgeneric/timidity.cfg",
        "demo/wads/**",
    ],
}
Path(".vercel/output/config.json").write_text(json.dumps(config, indent=2) + "\n")
PY
