#!/usr/bin/env bash
# Run only on an approved, disposable macOS CI runner with Xcode installed.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
SIMULATOR_ID=""
cleanup() {
python3 - <<'PYLOG'
from pathlib import Path
for path in Path('artifacts').glob('*.log'):
    data = path.read_bytes()
    if len(data) > 2_000_000:
        path.write_bytes(b'[log truncated to final 2 MB]\n' + data[-2_000_000:])
PYLOG
  if [[ -n "$SIMULATOR_ID" ]]; then
    xcrun simctl shutdown "$SIMULATOR_ID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Select the newest installed stable Xcode, never download another runtime.
DEVELOPER_DIR="$(python3 - <<'PY'
import glob, os, re, subprocess
candidates = []
for app in glob.glob('/Applications/Xcode*.app'):
    if re.search(r'beta|preview|release.?candidate|\brc\b', app, re.I):
        continue
    developer = app + '/Contents/Developer'
    result = subprocess.run([developer + '/usr/bin/xcodebuild', '-version'],
                            capture_output=True, text=True,
                            env={**os.environ, 'DEVELOPER_DIR': developer})
    if result.returncode or re.search(r'beta|preview|candidate', result.stdout, re.I):
        continue
    match = re.search(r'^Xcode ([0-9.]+)', result.stdout)
    if match:
        candidates.append((tuple(map(int, match[1].split('.'))), developer))
if not candidates:
    raise SystemExit('No installed stable Xcode found; stopping without downloads.')
print(max(candidates)[1])
PY
)"
export DEVELOPER_DIR
{
  echo "source_commit=$(git rev-parse HEAD)"
  echo "workflow_run=${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-local}/actions/runs/${GITHUB_RUN_ID:-local}"
  echo "runner_arch=$(uname -m)"
  echo "developer_dir=$DEVELOPER_DIR"
  xcodebuild -version
  swift --version
  echo 'initial_arguments=--demo (seed 42; save writes suppressed)'
  echo 'settled_arguments=--demo --demo-clear (real first legal clear before render; no animation)'
} | tee artifacts/provenance.txt

# Portable engine unit tests run on the macOS host, not on an iPhone.
swift test 2>&1 | tee artifacts/core-tests.log

# One already-installed, available iPhone; prefer newest iOS runtime.
xcrun simctl list devices available --json > "$RUNNER_TEMP/starfall-devices.json"
SIMULATOR_ID="$(python3 - "$RUNNER_TEMP/starfall-devices.json" <<'PY'
import json, re, sys
candidates = []
for runtime, devices in json.load(open(sys.argv[1]))['devices'].items():
    if '.iOS-' not in runtime:
        continue
    version = tuple(map(int, re.findall(r'\d+', runtime.split('.iOS-')[-1])))
    if version < (17,):
        continue
    for device in devices:
        if device.get('isAvailable') and device['name'].startswith('iPhone'):
            candidates.append((version, device['name'], device['udid']))
if not candidates:
    raise SystemExit('No installed iOS 17+ iPhone simulator; stopping without downloads.')
print(max(candidates)[2])
PY
)"
echo "simulator_udid=$SIMULATOR_ID" | tee -a artifacts/provenance.txt
# Record only selected device metadata, not an unrelated device inventory.
python3 - "$RUNNER_TEMP/starfall-devices.json" "$SIMULATOR_ID" >> artifacts/provenance.txt <<'PY'
import json, sys
for runtime, devices in json.load(open(sys.argv[1]))['devices'].items():
    for device in devices:
        if device['udid'] == sys.argv[2]:
            print('simulator_runtime=' + runtime)
            print('simulator_name=' + device['name'])
PY

# No provisioning, Apple account, certificate, or physical-device signing.
# Simulator ad-hoc signing is allowed and uses no private signing credential.
# This single ARM64 simulator run must use the same architecture for app and package.
# These command-line overrides do not change physical-device/distribution settings.
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -configuration Debug -sdk iphonesimulator \
  -destination "platform=iOS Simulator,arch=arm64,id=$SIMULATOR_ID" \
  -derivedDataPath "$RUNNER_TEMP/starfall-derived" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build \
  2>&1 | tee artifacts/native-build.log

# simctl reports an error when booting a device that is already booted.
state="$(xcrun simctl list devices --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["state"] for xs in d["devices"].values() for x in xs if x["udid"]==sys.argv[1]))' "$SIMULATOR_ID")"
if [[ "$state" != Booted ]]; then xcrun simctl boot "$SIMULATOR_ID"; fi
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl status_bar "$SIMULATOR_ID" override --time '9:41' --batteryState charged --batteryLevel 100
APP="$RUNNER_TEMP/starfall-derived/Build/Products/Debug-iphonesimulator/Starfall.app"
test -d "$APP"
xcrun simctl install "$SIMULATOR_ID" "$APP"
capture_state() {
  local state_name="$1"
  shift
  xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" com.starfall.prototype "$@" | tee "artifacts/${state_name}-launch.log"
  local pid
  pid="$(awk -F ': ' '/com.starfall.prototype:/ {print $NF}' "artifacts/${state_name}-launch.log" | tail -1)"
  [[ "$pid" =~ ^[0-9]+$ ]]
  sleep 5
  kill -0 "$pid"
  xcrun simctl io "$SIMULATOR_ID" screenshot "artifacts/${state_name}.png"
  kill -0 "$pid"
}
capture_state initial-board --demo
# The app calls the real first legal Game.tap before presenting this second
# deterministic board. This is a settled-state capture, not animation evidence.
capture_state post-clear-settled-board --demo --demo-clear
printf '%s\n' 'PASS: both demo launches accepted; each app process alive after 5s; both screenshots captured.' \
  'The second launch applies a real deterministic clear before rendering; animation is not exercised.' \
  'This is a launch/liveness smoke check, not an automated visual or interaction assertion.' | tee artifacts/smoke-result.txt
(cd artifacts && shasum -a 256 *.png > screenshot-sha256.txt)
# Keep artifacts small: no app bundle, DerivedData, simulator disk, or video.
