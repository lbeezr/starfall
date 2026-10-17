# Pacing cue and native candidate handoff

**Historical handoff:** The user subsequently selected B for production. Its current owner is [the adoption contract](PACING_ADOPTION.md); reproduce the commands below only from their pinned historical source. The current export tool is retired.

**Status:** PARTIAL handoff; source committed, native gaps remain · **Owner:** task 4 · **Updated:** October 17, 2026

The cue reads Store's committed `nextShowerCadence`: “Faster after next shower,” “Faster showers,” and “Breathing window.” Baseline A has no added cue. No Core, scheduler, generation or fixture algorithm changes. A persistent sibling outside the board/scroll content keeps the warning available at largest text sizes. Non-color symbols accompany text; focus exposes complete interval wording. Automatic speech is limited to the warning and breathing entry during active play, with no count chatter or safety promise.

**Next action:** Task 1 adapts the narrow anchors to current main; task 6 exports that combined committed source on its own healthy simulator and closes the native gaps. Task 5 owns measurement. Human comprehension and actual VoiceOver remain open; full VoiceOver belongs to release-candidate validation.

## Observable acceptance

- Baseline A retains its layout and has no phase cue through candidate boundaries.
- At count 9, the exact warning is visible. Count 10 exposes faster passage; count 13 exposes breathing window; count 16 removes it. Manual actions use the same Store state.
- Largest text exposes full wording while Next shower remains reachable, with no clipped cue or shrunken text. Settings removes the cue from the view tree and restores it on dismissal.
- Normal motion and system Reduce Motion retain labels and native controls. Record motion separately from screenshots. Normal motion is never suppressed to make assertions pass.

**Candidate source:** `c9cde8a25af07a34bdbed7039168a0982ee2445f` (source/test revision; later evidence-only commits do not change its app). Use this exact ref for reproduction.

## Export and run

From a checkout containing this task's commit, choose a new output directory:

```sh
python3 tools/mechanics/prepare-pacing-candidate.py --source c9cde8a25af07a34bdbed7039168a0982ee2445f --output /tmp/starfall-pacing-candidate-task6
xcodebuild -project /tmp/starfall-pacing-candidate-task6/Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=<PRIVATE-SIMULATOR-UUID>' -derivedDataPath /tmp/starfall-pacing-task6 CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -parallel-testing-enabled NO -only-testing:StarfallUITests/PacingCueUITests test
```

Candidate launches use the same `com.starfall.prototype` simulator app identity:

```sh
xcrun simctl launch <PRIVATE-SIMULATOR-UUID> com.starfall.prototype --starfalls-reset --starfalls-seed=5 --pacing-policy=B
```

Use `--pacing-policy=A` for baseline. B requires a reset; it is not persisted or restored as policy. Every B launch begins a new explicitly selected comparison. Export defaults use `starfall.pacing.candidate`; normal saves are untouched. The script performs no build, install, push or network operation and refuses existing output paths. Debug simulator code alone selects policy; normal Debug/Release source has no selection route. Exported Release retains A; Release B is unsupported. B alone reserves a constant slot from round start, measured with the longest cue at the actual text size. This prevents phase changes from resizing the SpriteKit scene and settling its in-flight shower. A retains its original layout. The hidden measurement view has a separate identifier and no accessibility presence. The one canonical fixture remains byte-identical and its SHA-256 is in `pacing-candidate-manifest.json`.

[Source-bound checks and failures](../evidence/pacing-cues-2026-10-17/README.md) keep compilation, interaction, motion, accessibility and human evidence separate.

Final task 4 results: 72 Core tests, normal Debug/Release builds and hygiene passed; largest-text and normal-motion B UI flows passed at the exact candidate source. The system Reduce Motion flow passed warning/clear/frame checks but stalled opening Settings; it was interrupted after the one recovery. Final screenshot/video review and full reduced-mode completion remain open. Earlier two hosted copy checks passed; final combined hosted rerun did not execute before interruption. See the evidence record for precise source/command limits.

Task 4 shut down its private simulator after the bounded stop and restored/read back its original stored Reduce Motion value (0); no post-cleanup UI check was run.

Task 4 owns private simulator `45D19CC2-B110-43E7-8C5E-1D7579EC737F` (“Starfall Pacing Cue QA”, iPhone 17e / iOS 27.0). Task 6 should use its own healthy simulator and DerivedData; do not run concurrent tests on this simulator. No phone installation or updater action is part of this handoff.

## Boundaries and remaining questions

Store/Core source is `3c09532d78400f877b4961073de05de3afa33828`. Task 4 adds only cue presentation, tests, export tooling and documentation. No separate phone app, decorative scene changes or exact forecast strip.

Task 6 owns automatic timing/interruption/trace integration and combined gameplay acceptance. Task 4's manual-boundary tests cannot establish usable reaction time, human preference or whether breathing windows enable satisfying actions. Ask players whether the warning means the next shower itself is faster, and whether “breathing window” implies safety; revise only from observed comprehension.

## Integration anchors for task 1

This branch deliberately remains based on `3c09532`; it does not merge later main. The coordinator reports remote `ca7f12e` with welcome/entry/ending changes, which this source has not validated. Preserve those routes and any ceremony accessibility gating during integration; final combined acceptance belongs to task 6.

The exporter requires exactly one original Store state initializer, one optional cue sibling block, one `cadenceCueCopy` declaration, one app sources-phase anchor, one UI export marker, and exactly two conditional safe-area branches. Missing/duplicated anchors raise an error; an incomplete output must not be built. It does not search-and-patch another checkout or silently fall back to A.

Layout assumptions: the cue is a persistent sibling of the gameplay scroll view, outside active board hit cells; Settings removes it entirely. Candidate B reserves its longest measured cue slot from round start so phase changes cannot resize the scene and invoke `onLayout`/`settlePresentation`. Its invisible measurement view has a separate identifier and no accessibility presence. A has no slot. Welcome/ceremony/ending must gate the cue together with the rest of gameplay, and the reserve must not introduce a new timing or input owner. Retain Store's committed `nextShowerCadence` and deadline; do not infer phase from pending animation. Native tests require one accessible cue, exact labels, unchanged cell frames, an actual clear and largest-text visibility. Re-run these after adapting the view rather than treating this branch's screenshots as combined-source acceptance.
