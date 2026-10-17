#!/usr/bin/env bash
# Developer-only native macOS export; no app dependencies.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
swift "$root/scripts/export-app-icon.swift" \
  "$root/Artwork/AppIcon/playful-tumble-source.png" \
  "$root/App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png"
