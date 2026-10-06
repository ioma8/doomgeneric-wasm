#!/usr/bin/env bash
set -euo pipefail

emsdk_version=6.0.11
emsdk_dir="${EMSDK_DIR:-/tmp/emsdk}"

if ! command -v emcc >/dev/null 2>&1; then
  if [ ! -d "$emsdk_dir" ]; then
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$emsdk_dir"
  fi
  "$emsdk_dir/emsdk" install "$emsdk_version"
  "$emsdk_dir/emsdk" activate "$emsdk_version"
  source "$emsdk_dir/emsdk_env.sh"
fi

make wasm
rm -rf dist
mkdir -p dist/wads
cp demo/doom.html dist/index.html
cp demo/doom.js demo/doom.wasm demo/doom.data dist/
cp demo/wads/*.wad dist/wads/
cp favicon.svg dist/

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
import os
import re
from pathlib import Path
from xml.sax.saxutils import escape

site_url = os.environ["SITE_URL"]
index = Path("dist/index.html")
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
Path("dist/sitemap.xml").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    f'<url><loc>{escape(site_url)}/</loc></url></urlset>\n'
)
PY
  if [ "${VERCEL_ENV:-}" = preview ]; then
    printf 'User-agent: *\nDisallow: /\n' > dist/robots.txt
  else
    printf 'User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' "$site_url" > dist/robots.txt
  fi
else
  echo "No production URL found; set SITE_URL to generate canonical metadata and sitemap." >&2
  printf 'User-agent: *\nAllow: /\n' > dist/robots.txt
fi
