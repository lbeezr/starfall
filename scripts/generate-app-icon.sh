#!/usr/bin/env bash
# Deterministic conversion of the original vector candidate. Requires Inkscape + ImageMagick.
# This is a developer-only tool; the app and CI have no added dependency.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="$root/App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png"
command -v inkscape >/dev/null || { echo 'Inkscape is required' >&2; exit 1; }
command -v magick >/dev/null || { echo 'ImageMagick is required' >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
inkscape "$root/scripts/starfall-app-icon.svg" --export-type=png \
  --export-filename="$tmp/icon.png" --export-width=1024 --export-height=1024
magick "$tmp/icon.png" -alpha off -colorspace sRGB -strip "PNG24:$output"
magick identify -format '%wx%h %[channels]\n' "$output"
