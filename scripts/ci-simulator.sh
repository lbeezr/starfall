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

# One real coordinate-tap/navigation flow, on the same simulator, without retries.
# Keep the result bundle on ephemeral runner storage; export only compact evidence.
UI_RESULT="$RUNNER_TEMP/starfall-ui.xcresult"
UI_EXPORT="$RUNNER_TEMP/starfall-ui-attachments"
xcrun xcresulttool help export attachments > artifacts/xcresulttool-attachments-help.txt
set +e
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -configuration Debug -sdk iphonesimulator \
  -destination "platform=iOS Simulator,arch=arm64,id=$SIMULATOR_ID" \
  -derivedDataPath "$RUNNER_TEMP/starfall-derived" \
  -only-testing:StarfallUITests/StarfallInteractionTests/testRealBoardTapAndNavigation \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 120 \
  -resultBundlePath "$UI_RESULT" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual test \
  2>&1 | tee artifacts/ui-tests.log
UI_STATUS=${PIPESTATUS[0]}
# Attempt compact evidence export even after a test failure. Keep its original
# exit status; attachment export must never turn a failed test into success.
xcrun xcresulttool get test-results summary --path "$UI_RESULT" --compact \
  > artifacts/ui-test-summary.json
UI_SUMMARY_STATUS=$?
xcrun xcresulttool export attachments --path "$UI_RESULT" --output-path "$UI_EXPORT" \
  > artifacts/ui-export.log 2>&1
UI_EXPORT_STATUS=$?
python3 - "$UI_EXPORT" "$UI_STATUS" <<'PY'
from pathlib import Path
import hashlib, json, shutil, sys
root = Path(sys.argv[1]).resolve()
test_passed = int(sys.argv[2]) == 0
summary = json.loads(Path('artifacts/ui-test-summary.json').read_text())
if test_passed and (summary.get('passedTests') != 1 or summary.get('failedTests') != 0):
    raise SystemExit('Expected exactly one passing UI test and zero failures; inspect summary.')
manifest_path = root / 'manifest.json'
manifest_bytes = manifest_path.read_bytes()
if len(manifest_bytes) > 250_000:
    raise SystemExit('Attachment manifest exceeds compact evidence limit.')
Path('artifacts/ui-export-manifest.json').write_bytes(manifest_bytes)
manifest = json.loads(manifest_bytes)

def objects(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from objects(child)

records = []
for name in ('real-touch-post-clear', 'real-touch-restarted'):
    matches = [x for x in objects(manifest)
               if str(x.get('suggestedHumanReadableName', '')).startswith(name)
               and x.get('exportedFileName')]
    if not matches and not test_passed:
        continue  # A later stage may not have been reached in the failed test.
    if len(matches) != 1:
        raise SystemExit(f'Expected exactly one named attachment {name}; found {len(matches)}.')
    source = (root / matches[0]['exportedFileName']).resolve()
    if root not in source.parents or source.is_symlink():
        raise SystemExit('Unexpected attachment path.')
    data = source.read_bytes()
    if not data.startswith(b'\x89PNG\r\n\x1a\n') or len(data) > 5_000_000:
        raise SystemExit(f'{name}: expected PNG below 5 MB; refusing oversized/unknown evidence.')
    target = Path('artifacts') / (name + '.png')
    shutil.copyfile(source, target)
    records.append({'name': name, 'file': target.name,
                    'sha256': hashlib.sha256(data).hexdigest(), 'export': matches[0]})
Path('artifacts/ui-attachment-manifest.json').write_text(json.dumps(records, indent=2) + '\n')
Path('artifacts/ui-evidence-status.json').write_text(json.dumps({
    'testPassed': test_passed, 'xcodebuildExitCode': int(sys.argv[2]),
    'namedScreenshotsExported': len(records),
    'partialEvidenceOnly': not test_passed}, indent=2) + '\n')
print(f'Exported {len(records)} named screenshot(s); testPassed={test_passed}.')
PY
UI_PARSE_STATUS=$?
set -e
(cd artifacts && shasum -a 256 *.png > screenshot-sha256.txt)
if [[ "$UI_STATUS" != 0 ]]; then
  printf '%s\n' "FAIL: native UI test (xcodebuild exit $UI_STATUS). Any exported UI screenshots are partial evidence only." \
    | tee artifacts/ui-result.txt
  exit "$UI_STATUS"
fi
if [[ "$UI_SUMMARY_STATUS" != 0 || "$UI_EXPORT_STATUS" != 0 || "$UI_PARSE_STATUS" != 0 ]]; then
  echo 'UI evidence export/validation failed; inspect logs. No complete UI-evidence success claim.' >&2
  exit 1
fi
printf '%s\n' 'PASS: one real coordinate-tap/navigation UI test and two exported XCTest screenshots.' \
  'See ui-test-summary.json and ui-attachment-manifest.json; no VoiceOver or rapid-input validation.' \
  | tee artifacts/ui-result.txt
(cd artifacts && shasum -a 256 *.png > screenshot-sha256.txt)
