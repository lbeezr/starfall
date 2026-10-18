"""Run one bounded simulator stage, preserving stdout and an execution receipt."""
import argparse
import datetime
import json
import os
import signal
from pathlib import Path
import subprocess
import sys
import time


def execute(label, limit, command, receipt):
    if not command or not 0 < limit <= 1200:
        raise ValueError('A command and a positive timeout at most 1200 seconds are required')
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    begin = time.monotonic()
    status = 1
    error = None
    print(f'START simulator stage {label}; timeout={limit}s', file=sys.stderr, flush=True)
    try:
        # simctl/xcrun may spawn helpers. A timeout owns the entire inherited
        # process group, not only the wrapper whose PID we can directly wait for.
        with subprocess.Popen(command, start_new_session=True) as process:
            try:
                status = process.wait(timeout=limit)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass  # The group completed between timeout and cancellation.
                process.wait()
                raise
        if status < 0:
            status = 128 - status
    except subprocess.TimeoutExpired as failure:
        status = 124; error = str(failure)
    except OSError as failure:
        status = 127; error = str(failure)
    elapsed = round(time.monotonic() - begin, 3)
    record = dict(stage=label, startedUTC=started, elapsedSeconds=elapsed,
                  limitSeconds=limit, exitCode=status, error=error)
    try:
        receipt.parent.mkdir(parents=True, exist_ok=True)
        with receipt.open('a') as output:
            output.write(json.dumps(record) + '\n')
    except OSError as failure:
        print(f'Cannot record simulator stage: {failure}', file=sys.stderr)
        if status == 0:
            status = 1
    print(f'END simulator stage {label}; elapsed={elapsed}s exit={status}', file=sys.stderr, flush=True)
    return status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--receipt', type=Path, default=Path('artifacts/simulator-stage-timings.jsonl'))
    parser.add_argument('label')
    parser.add_argument('limit', type=float)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    return execute(args.label, args.limit, args.command, args.receipt)


if __name__ == '__main__':
    raise SystemExit(main())
