#!/bin/sh
set -eu

# All compilation/cache artifacts stay outside the app and Swift package builds.
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
output=${1:-"$root/tools/gameplay-study/results-2026-10-16"}
scratch=$(mktemp -d "${TMPDIR:-/tmp}/starfall-gameplay.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir -p "$output" "$scratch/module-cache"
cp "$root/Sources/StarfallCore/Game.swift" "$scratch/Game.swift"
cp "$root/tools/gameplay-study/main.swift" "$scratch/main.swift"
{
    date -u '+execution_utc=%Y-%m-%dT%H:%M:%SZ'
    git -C "$root" rev-parse HEAD
    swift --version
    shasum -a 256 "$scratch/Game.swift" "$scratch/main.swift" "$root/tools/gameplay-study/run.sh"
} > "$output/provenance.txt"
swiftc -O -module-cache-path "$scratch/module-cache" "$scratch/Game.swift" "$scratch/main.swift" -o "$scratch/gameplay-study"
"$scratch/gameplay-study" "$output"
shasum -a 256 "$output/summary.json" "$output/rounds.csv" "$output/reachable-examples.json" >> "$output/provenance.txt"
