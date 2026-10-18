# Sourced by CI; no boot/shutdown happens merely by loading this file.
STARFALL_SIMULATOR_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARFALL_OWNED_SIMULATOR=""

timed_simctl() {
  python3 "$STARFALL_SIMULATOR_TOOLS_DIR/simulator-command.py" \
    --receipt "${STARFALL_SIMULATOR_RECEIPT:-artifacts/simulator-stage-timings.jsonl}" "$@"
}

start_simulator() {
  local simulator_id="$1" initial_state="$2"
  if [[ "$initial_state" != Booted ]]; then
    # Own the attempt even if boot partially succeeds then fails or times out.
    STARFALL_OWNED_SIMULATOR="$simulator_id"
    timed_simctl boot 60 xcrun simctl boot "$simulator_id"
  fi
}

cleanup_simulator() {
  local simulator_id="$STARFALL_OWNED_SIMULATOR"
  STARFALL_OWNED_SIMULATOR=""
  if [[ -n "$simulator_id" ]]; then
    timed_simctl shutdown 30 xcrun simctl shutdown "$simulator_id"
  fi
}
