# Repository scripts

Hygiene checks, native CI validation and app-icon export tooling.

## Start here

Run `python3 scripts/ci-hygiene.py` and `git diff --check` from the root. See [app icon export](README-app-icon.md) before regenerating branding; inspect `ci-simulator.sh` for its native environment requirements. The former icon SVG is historical.


## One-app iPhone updates

`device-update.py` is a local macOS service, not an iPhone network feature. It fetches public GitHub main, checks exact-source CI, runs local core tests, signs with local Xcode, and updates regular Starfall in place. It never installs lab identities or launches/reset the game. See [build/testing policy](../docs/DEVELOPMENT_BUILDS.md). The Mac must be awake, logged in, with Xcode signing and a trusted connected iPhone.

```sh
python3 scripts/device-update.py configure --device <iPhone-UDID> --team <development-team>
python3 scripts/device-update.py run
python3 scripts/device-update.py status
python3 scripts/device-update.py enable
python3 scripts/device-update.py disable
python3 scripts/test_device_update.py
```

Enable copies the updater and fingerprint helper to `~/Library/Application Support/Starfall Device Updates/` and registers `~/Library/LaunchAgents/com.starfall.device-updates.plist` with a two-minute interval. Disable unloads/removes that agent and retains installed apps, config, backups and diagnostic state. Re-enable from updated repository scripts when updating the service itself. Configuration contains device/team identifiers, not account credentials. Changing the device/team invalidates local installation/signing markers under the same process lock; installed apps and backups remain untouched. Pending broader CI does not delay development delivery after local tests/signature pass; an explicit CI failure blocks a new install. Cancelled/timed-out remote runs are unavailable evidence; local core/signature gates remain mandatory. Reconfiguration and service reload share the active-update lock, so reloading cannot interrupt a build or install. Build logs are replaced per build; recurring logs are trimmed at 2 MB. `installed.json` records the actual installed source/build, while `status.json` explains waiting/errors. Run the behavior checks without a phone or network.

`native_test_plan.py` keeps source-counted development and RC native matrices. Development defers six named actual VoiceOver sessions while retaining all other UI/hosted assertions and zero-skip requirements for selected tests. Run `STARFALL_ACCEPTANCE_STAGE=rc bash scripts/ci-simulator.sh` on an approved disposable runner for the full matrix; it requires tooling/OS supporting actual VoiceOver and does not replace physical-iPhone RC acceptance. Test matrix policy with `python3 scripts/test_native_test_plan.py`.

Build identity includes `Package.swift`, optional root/package-workspace resolution files and runtime/config/project inputs. Markdown documentation (including folder READMEs), tests and user Xcode state do not trigger reinstall. The versioned recipe intentionally changes the fingerprint once when adopted. CI is rechecked after signature verification immediately before installation; a newly known failure retains the verified cached build and existing app. Pending/unavailable CI retains the existing development policy, with full hosted/UI acceptance owned by integration and RC. Reload the installed service with `device-update.py enable` after a service/helper change, once its update lock is free.

The updater queries the real app installation on every check. URL/version mismatch, a missing app or a legacy receipt triggers a verified current-main repair, including when source/runtime fingerprints are unchanged. It rejects non-descendant main, re-fetches before delivery, and verifies post-install identity before recording success. Device inventory failure defers the operation. See [delivery guards and their permission limit](../docs/DEVELOPMENT_BUILDS.md#reject-stale-delivery-and-detect-external-replacements). The first guarded run refreshes an old receipt through one verified reinstall; it never launches or resets the app. Tests include real Git ancestry plus mocked device/build/CI failures.

`generate-celebration-audio.py` deterministically regenerates the two original local WAV celebration cues in `App/Audio`, using only Python’s standard library and no external samples or service.


## Release and RC platform gates

`ci-simulator.sh` builds both Debug and Release in the existing job. The primary iPhone matrix explicitly excludes the one tablet-only landscape method; it is owned by the separate RC tablet selection, not silently skipped. All other selected tests retain zero-failure/zero-skip count checks.

`python3 scripts/rc-platforms.py --plan-only` checks installed simulators without booting or downloading anything. Full `python3 scripts/rc-platforms.py` requires an iOS 17 iPhone and an iPad, runs three focused native flows per role with bounded subprocess/test waits, and validates exact pass counts. It boots/shuts down only its own previously unbooted selections. Logs and summaries stay under ignored `artifacts/`; successful raw result bundles are temporary. Failed bundles are retained per role up to 64 MB each; larger bundles leave a bounded inventory plus the trimmed log and any exportable summary. The execution manifest records primary and cleanup errors separately, and the platform plan records failure before temporary storage is removed. Missing minimum runtime/tablet blocks RC acceptance rather than substituting a newest-OS phone. The RC CI stage preflights these requirements before native work, then runs the platform checks after the main matrix. Run `python3 scripts/test_rc_platforms.py` for selection/count/command regression checks.

The manual workflow exposes `dev`/`rc` under the existing budget confirmation; push triggers, permissions, runner count and 35-minute limit are unchanged. Full actual VoiceOver on the physical iPhone remains a separate required RC acceptance record; a successful platform script cannot replace it.

## Primary CI simulator lifecycle

`ci-simulator.sh` sources `simulator-lifecycle.sh` and runs native simulator operations through `simulator-command.py`. Inventory, boot, readiness, status bar, install, launches and captures have bounded waits and compact stage receipts; stdout is preserved for launch PID parsing. Cleanup owns only a simulator this run attempted to boot. A primary failure survives cleanup failure, while cleanup failure after otherwise successful work fails the run. Logs are trimmed by reading their tail. Run `python3 scripts/test_simulator_lifecycle.py` for real subprocess timeout/receipt checks and fake-simctl execution of the actual primary CI cleanup prefix; these tests do not boot devices or claim a native build. The existing workflow runs them in its existing verification step.
