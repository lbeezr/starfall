# Local main synchronization — October 17, 2026

**Status:** Verified for history integration and working-file preservation. Local `main` includes GitHub main without dropping unpublished commits or publishing unfinished work.

Merged local source `5ddbeac41acd011dfbdee673a654de42310558f4` and GitHub main `4230b895fe23951919321df1ade59d6d4c921dc4` into `bf0299c`. Both parents are verified ancestors. The local-only 19-commit history is retained; the merge does not make local and remote refs identical or publish local experiments.

Three committed documentation conflicts were reconciled in an isolated worktree: retain the new writing/layout structure while keeping the later Phase/Surge implementation, exposure and agent-simulated-play facts. All local trial code, source-bound evidence and save/rule boundaries remain intact. Restoring the working changes required no manual conflict resolution.

## Preservation

Persistent backup: `/Users/lbeezr/.codex/backups/starfall-main-sync-20261017-110251`. It contains original and immediate pre-stash copies/manifests, staged/unstaged binary patches and a preservation report. Safety branch: `codex/backup-main-before-sync-20261017-110251`.

Of 80 modified/untracked files in the pre-stash snapshot, 78 restored byte-for-byte. README and roadmap necessarily incorporate upstream documentation changes; every nonempty original in-progress added line remains present. No backed-up file is missing. App/test/project edits and untracked environment/branding/tool assets retain their original bytes. Ignored build/artifact files were not cleaned. Concurrent work after the snapshot remains separate from this preservation claim. The restored changes remain uncommitted/unstaged; this evidence commit includes only this file.

## Checks and limits

- Clean merged source `bf0299c`: `swift test`, 61 passed; `python3 scripts/ci-hygiene.py` and `git diff --check`, passed.
- Clean merged source: Xcode 27.1 Debug simulator build and `test_sim`, `ARCHS=arm64 -parallel-testing-enabled NO -only-testing:StarfallUITests/FallingSkyInteractionTests/testFirstShowerIsPlayableAndManualInputStaysPaused`, passed on iPhone 17e / iOS 27.0 (`1199FBAF-FCA7-4F0D-BD49-8282154CC9EE`). Result: `test_sim_2026-10-17T15-04-22-056Z_pid43533_1b5ae7c8.xcresult` under the local XcodeBuildMCP workspace.
- Restored primary workspace: Debug simulator `build_sim`, `ARCHS=arm64`, passed with no warnings/errors. Log: `build_sim_2026-10-17T15-05-48-235Z_pid43533_22a8347f.log`. This extra build includes preserved UI/environment/test/project changes and does not establish their feature acceptance. Dirty paths at that check are captured in the backup/status record; the preservation report identifies the source relationship.
- No new rule/save or routing behavior was introduced by synchronization. No new claim of interruption matrices, visual/full-animation acceptance, actual VoiceOver or physical-device checks. Existing source-bound PR and experiment records keep their limits.
