# RC subprocess timeout ownership

**Result:** Verified for the bounded tooling contract · **Owner:** factory coordinator · **Date:** October 22, 2026

[Issue #215](https://github.com/lbeezr/starfall/issues/215) came from an active readiness worker: the RC runner timed out its direct child while an inherited grandchild continued writing after failure evidence had been finalized. A real Python parent/grandchild reproduced that violation through the actual RC `run` function with simulated Apple commands. No real Apple helper escape was demonstrated.

The primary simulator stage runner and RC runner now share `scripts/owned_process.py`. Each invocation owns a new process group; timeout or interruption kills that inherited group and reaps its direct child before returning failure. The helper preserves completed results, nonzero exceptions and partial timeout output. It does not drain inherited pipes after timeout, so a separately detached service cannot prolong that wait. Unrelated processes and independently detached services remain outside the owned group.

**Next action:** none for #215's bounded acceptance. Device updater process ownership remains a separate existing deployment-tooling risk. Minimum-iOS, physical performance and actual VoiceOver acceptance stay open in their existing leaves.

## Source and checks

Base: clean merged main `7f3a8b62975b2ef3314f3badea2308613f2208e2`. The worker patch's seven prerequisites matched byte for byte, including #205's integrated RC selector; its applied files matched the returned artifact. [verification.json](verification.json) records input hashes, commands and counts. Publication and automatic closure are recorded on the closing PR. No Swift, app, save, signing, installation or updater code changed.

| Check | Observed result |
| --- | --- |
| `PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_rc_platforms.py` | 14 passed. Includes real descendant cancellation before RC evidence retention, direct-child reaping, unchanged retained bundle/log and timeout remaining primary when shutdown also fails. |
| `PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_simulator_lifecycle.py` | 13 passed. Includes real owned-group cancellation, unrelated-process survival, partial stdout/stderr, interruption, missing command, signal and receipt failure semantics. |
| `PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_native_test_plan.py` | 3 passed; source-count and selection contracts retained. |
| `python3 scripts/ci-hygiene.py`, `git diff --check` | Passed, including the staged new helper. |
| Primary wrapper → `xcrun simctl list devices available --json`, 30-second bound | Passed against installed Apple tooling, exit 0 in 0.357 seconds. Read-only inventory only. |

The actual RC cancellation regression starts a real grandchild with a delayed write, lets the command time out, verifies the retained failure, then checks after the write deadline that neither the sentinel nor late log output appeared. Cleanup failure is deliberately induced and remains secondary. These tests exercise process behavior rather than only mocking subprocess return values.

The existing workflow's path filter includes the new shared dependency; no new job, runner, paid dispatch, required check or human sign-off was added. Existing exact-count and zero-skip gates are unchanged.

## Limits and failure history

The scratch implementation initially expected empty timeout stderr as bytes; standard `TimeoutExpired` preserves `None` for an empty stream. The new regression was corrected to emit and assert actual partial stderr. Existing assertions were not relaxed. The final repository checks above passed after integration.

After testing, an owned-iPad cleanup attempt reported it was already `Shutdown` (exit 149); no unrelated simulator was touched. This is retained as a cleanup observation, not a native test failure or an Apple-operation pass. The tests use simulated Apple operations with real Python descendants; the inventory smoke check alone does not establish native boot/build, RC platform or physical-device acceptance.
