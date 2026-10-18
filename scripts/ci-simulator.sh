#!/usr/bin/env bash
# Run only on an approved, disposable macOS CI runner with Xcode installed.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
# No previous UI acceptance can survive an early build/boot failure.
python3 scripts/export_native_evidence.py --reset-only
rm -f artifacts/simulator-stage-timings.jsonl
SIMULATOR_ID=""
source scripts/simulator-lifecycle.sh
cleanup() {
  local original_status=$? cleanup_status=0
python3 - <<'PYLOG' || cleanup_status=1
from pathlib import Path
for path in Path('artifacts').glob('*.log'):
    if path.stat().st_size > 2_000_000:
        with path.open('rb') as source:
            source.seek(-2_000_000, 2)
            tail = source.read(2_000_000)
        path.write_bytes(b'[log truncated to final 2 MB]\n' + tail)
PYLOG
  cleanup_simulator || cleanup_status=$?
  if [[ "$original_status" != 0 ]]; then return "$original_status"; fi
  return "$cleanup_status"
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

# Cheap tracked-file checks precede native work; no additional CI job or download.
python3 scripts/ci-hygiene.py

# Portable engine unit tests run on the macOS host, not on an iPhone.
swift test 2>&1 | tee artifacts/core-tests.log

# Keep native coverage tied to the checked-in XCTest methods. A newly added
# source file missing from its Xcode target must fail this gate, not go unnoticed.
python3 scripts/native_test_plan.py --stage "${STARFALL_ACCEPTANCE_STAGE:-dev}"
if [[ "${STARFALL_ACCEPTANCE_STAGE:-dev}" == rc ]]; then
  python3 scripts/rc-platforms.py --plan-only
fi
UI_MATRIX_ARGUMENTS=()
while IFS= read -r identifier; do
  [[ -z "$identifier" ]] || UI_MATRIX_ARGUMENTS+=("-skip-testing:$identifier")
done < artifacts/native-test-exclusions.txt

# One already-installed, available iPhone; prefer newest iOS runtime.
timed_simctl inventory 30 xcrun simctl list devices available --json > "$RUNNER_TEMP/starfall-devices.json"
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

# Start the selected simulator before compiling so boot can overlap the app build.
# simctl reports an error when booting a device that is already booted.
state="$(python3 - "$RUNNER_TEMP/starfall-devices.json" "$SIMULATOR_ID" <<'PY_STATE'
import json, sys
inventory = json.load(open(sys.argv[1]))
print(next(device['state'] for devices in inventory['devices'].values()
           for device in devices if device['udid'] == sys.argv[2]))
PY_STATE
)"
start_simulator "$SIMULATOR_ID" "$state"

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

# Compile the actual Release routing/resources in the same bounded job.
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$RUNNER_TEMP/starfall-release" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build \
  2>&1 | tee artifacts/release-build.log
test -s "$RUNNER_TEMP/starfall-release/Build/Products/Release-iphonesimulator/Starfall.app/Assets.car"

# Verify the shipped resource, not merely the source declaration.
APP="$RUNNER_TEMP/starfall-derived/Build/Products/Debug-iphonesimulator/Starfall.app"
python3 - "$APP/PrivacyInfo.xcprivacy" <<'PY'
from pathlib import Path
import hashlib, json, plistlib, sys
source = Path('Config/PrivacyInfo.xcprivacy')
bundled = Path(sys.argv[1])
source_data = plistlib.loads(source.read_bytes())
bundled_data = plistlib.loads(bundled.read_bytes())
if source_data != bundled_data:
    raise SystemExit('Built privacy manifest differs from source declaration.')
api_entries = bundled_data.get('NSPrivacyAccessedAPITypes', [])
if not any(x.get('NSPrivacyAccessedAPIType') == 'NSPrivacyAccessedAPICategoryUserDefaults'
           and 'CA92.1' in x.get('NSPrivacyAccessedAPITypeReasons', []) for x in api_entries):
    raise SystemExit('Built privacy manifest lacks app-local UserDefaults reason CA92.1.')
Path('artifacts/privacy-manifest-result.json').write_text(json.dumps({
    'passed': True, 'matchesSourcePlist': True, 'userDefaultsReason': 'CA92.1',
    'sourceSHA256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'bundledSHA256': hashlib.sha256(bundled.read_bytes()).hexdigest()
}, indent=2) + '\n')
print('PASS: built privacy manifest parses, matches source, and declares UserDefaults CA92.1.')
PY

# Check compiled app icon metadata and asset packaging; visual review is separate.
python3 - "$APP" <<'PY'
from pathlib import Path
import json, plistlib, sys
app = Path(sys.argv[1])
info = plistlib.loads((app / 'Info.plist').read_bytes())
primary = info.get('CFBundleIcons', {}).get('CFBundlePrimaryIcon', {})
if primary.get('CFBundleIconName') != 'AppIcon' or not primary.get('CFBundleIconFiles'):
    raise SystemExit('Built app lacks expected AppIcon primary icon metadata.')
assets = app / 'Assets.car'
if not assets.is_file() or assets.stat().st_size == 0:
    raise SystemExit('Built app lacks compiled asset catalog.')
Path('artifacts/app-icon-result.json').write_text(json.dumps({
    'passed': True, 'primaryIcon': primary,
    'compiledAssetCatalogBytes': assets.stat().st_size,
    'visualInspectionPerformed': False}, indent=2) + '\n')
print('PASS: built app has AppIcon metadata and nonempty compiled asset catalog.')
PY

# Keep the readiness barrier before status-bar setup, installation and launches.
timed_simctl boot-ready 180 xcrun simctl bootstatus "$SIMULATOR_ID" -b
timed_simctl status-bar 60 xcrun simctl status_bar "$SIMULATOR_ID" override --time '9:41' --batteryState charged --batteryLevel 100
test -d "$APP"
timed_simctl install 300 xcrun simctl install "$SIMULATOR_ID" "$APP"
capture_state() {
  local state_name="$1"
  shift
  timed_simctl "${state_name}-launch" 300 xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" com.starfall.prototype "$@" | tee "artifacts/${state_name}-launch.log"
  local pid
  pid="$(awk -F ': ' '/com.starfall.prototype:/ {print $NF}' "artifacts/${state_name}-launch.log" | tail -1)"
  [[ "$pid" =~ ^[0-9]+$ ]]
  sleep 5
  kill -0 "$pid"
  timed_simctl "${state_name}-screenshot" 60 xcrun simctl io "$SIMULATOR_ID" screenshot "artifacts/${state_name}.png"
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

# All native input flows, sequentially on the same simulator, without retries.
# Keep the result bundle on ephemeral runner storage; export only compact evidence.
UI_RESULT="$RUNNER_TEMP/starfall-ui.xcresult"
UI_EXPORT="$RUNNER_TEMP/starfall-ui-attachments"
xcrun xcresulttool help export attachments > artifacts/xcresulttool-attachments-help.txt
set +e
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -configuration Debug -sdk iphonesimulator \
  -destination "platform=iOS Simulator,arch=arm64,id=$SIMULATOR_ID" \
  -derivedDataPath "$RUNNER_TEMP/starfall-derived" \
  -only-testing:StarfallUITests ${UI_MATRIX_ARGUMENTS[@]+"${UI_MATRIX_ARGUMENTS[@]}"} \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 240 \
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
python3 scripts/export_native_evidence.py "$UI_EXPORT" "$UI_STATUS"
UI_PARSE_STATUS=$?
set -e
(cd artifacts && shasum -a 256 *.png > screenshot-sha256.txt)
# Preserve UI failure while still gathering independent hosted-test evidence.
UI_FINAL_STATUS=0
if [[ "$UI_STATUS" != 0 ]]; then
  printf '%s\n' "FAIL: native UI test (xcodebuild exit $UI_STATUS). Any exported UI screenshots are partial evidence only." \
    | tee artifacts/ui-result.txt
  UI_FINAL_STATUS="$UI_STATUS"
elif [[ "$UI_SUMMARY_STATUS" != 0 || "$UI_EXPORT_STATUS" != 0 || "$UI_PARSE_STATUS" != 0 ]]; then
  echo 'UI evidence export/validation failed; inspect logs. No complete UI-evidence success claim.' >&2
  UI_FINAL_STATUS=1
else
  python3 - <<'PY'
from pathlib import Path
import json
summary = json.loads(Path('artifacts/ui-test-summary.json').read_text())
evidence = json.loads(Path('artifacts/ui-evidence-status.json').read_text())
result = (f'PASS: all {summary["passedTests"]} native UI tests and '
          f'{evidence["namedScreenshotsExported"]} named XCTest screenshots.\n'
          'See ui-test-summary.json and ui-attachment-manifest.json; no actual VoiceOver, device feel, or audio validation.\n')
Path('artifacts/ui-result.txt').write_text(result)
print(result, end='')
PY
fi

# All hosted app tests cover the store, rendering, artwork and interruption paths.
# Keep their result separate so they cannot satisfy the native UI gate.
HOSTED_RESULT="$RUNNER_TEMP/starfall-hosted.xcresult"
set +e
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -configuration Debug -sdk iphonesimulator \
  -destination "platform=iOS Simulator,arch=arm64,id=$SIMULATOR_ID" \
  -derivedDataPath "$RUNNER_TEMP/starfall-derived" \
  -only-testing:StarfallAppTests \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 180 \
  -resultBundlePath "$HOSTED_RESULT" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual test \
  2>&1 | tee artifacts/hosted-tests.log
HOSTED_STATUS=${PIPESTATUS[0]}
xcrun xcresulttool get test-results summary --path "$HOSTED_RESULT" --compact \
  > artifacts/hosted-test-summary.json
HOSTED_SUMMARY_STATUS=$?
set -e
if [[ "$HOSTED_STATUS" != 0 ]]; then
  echo "FAIL: hosted app tests (xcodebuild exit $HOSTED_STATUS)." | tee artifacts/hosted-result.txt
  exit "$HOSTED_STATUS"
fi
if [[ "$HOSTED_SUMMARY_STATUS" != 0 ]]; then
  echo 'Hosted summary export failed.' >&2
  exit 1
fi
python3 - <<'PY'
import json
from pathlib import Path
summary = json.loads(Path('artifacts/hosted-test-summary.json').read_text())
expected = json.loads(Path('artifacts/native-test-expectations.json').read_text())['StarfallAppTests']['expectedCount']
if (summary.get('passedTests') != expected or summary.get('failedTests') != 0
        or summary.get('skippedTests') != 0 or summary.get('totalTestCount') != expected):
    raise SystemExit(f'Expected {expected} passing hosted app tests from source, zero failures/skips; inspect summary and native-test-expectations.json.')
Path('artifacts/hosted-result.txt').write_text(
    f'PASS: all {expected} hosted app tests. See hosted-test-summary.json for results; UI gesture evidence is separate.\n')
PY

# RC support claims require separate minimum-iOS and real tablet selections.
# The planner fails closed if an installed runtime/device is missing; no downloads.
if [[ "${STARFALL_ACCEPTANCE_STAGE:-dev}" == rc ]]; then
  python3 scripts/rc-platforms.py
fi

# A passing hosted suite never erases a failed UI audit or evidence gate.
exit "$UI_FINAL_STATUS"
