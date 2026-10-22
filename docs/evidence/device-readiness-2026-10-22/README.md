# Ready preparation for the remaining device evidence

**Result:** Environment inspected; physical observations/profiles and minimum-OS acceptance not run · **Source:** `5166e6ec998e6c02ea540d169086c0c65c2f84c8` · **Date:** October 22, 2026

This read-only readiness pass advances [#207](https://github.com/lbeezr/starfall/issues/207), [#208](https://github.com/lbeezr/starfall/issues/208) and [#209](https://github.com/lbeezr/starfall/issues/209) without closing them. No build, boot, test, profile, install, device launch or download was performed by the readiness worker. Concurrent #205 verification belongs to its own evidence. The [current Story observation packet](../../design/CURRENT_STORY_PLAYTEST.md) separately prepares #206; it contains no participant results.

| Resource | Observed inventory | Next action / limit |
| --- | --- | --- |
| Toolchain | `/Applications/Xcode.app`, Xcode 27.1 / `27A9275`; no alternate Xcode app found | Apple lists iOS 17+ simulator support for this toolchain; do not assume an older Xcode is required. |
| Runtime | Installed iOS 27.0 / `24A434` and 27.1 / `24A94425`; no iOS 17 runtime | Obtain an Apple-supported iOS 17 runtime, then select/create its iPhone simulator and run the existing minimum-OS role after #205. Runtime acquisition and that acceptance remain unperformed. |
| Simulator | 46 devices on 27.0 (34 phone, 12 tablet), one phone on 27.1 | Current-OS native preparation is available under an exclusive reservation. Existing booted simulators belong to their owners; do not reset/shut them down incidentally. |
| Instruments | 27.1; Game Performance Overview, Game Performance, Game Memory, Metal System Trace, Power Profiler, Allocations and Leaks | Instrument availability is not a measured result. Reserve hardware and select a bounded trace before profiling. |
| Physical hardware | Original paired iPhone 16 Pro Max / iOS 26.6.2 listed on local network with idle/disconnected tunnel; no physical iPad in the inventory | Phone reachability is unprobed, not established unavailable. Follow the canonical wireless check if a device session is authorized. A physical iPad/provider still needs identification. No installation is implied. |

Commands inspected: `xcodebuild -version`, `xcrun simctl list runtimes/devices --json`, `xcrun xctrace list templates/devices`, bounded CoreDevice inventory, and `/Applications` Xcode names. The sandbox initially refused CoreSimulator service access; identical read-only inventory succeeded with escalation. That refusal is not evidence of absent runtimes. Raw inventory is disposable under `/private/tmp/starfall-factory-audit-engineering`; no credentials or session data were exported.

Apple's [Xcode support matrix](https://developer.apple.com/xcode/system-requirements) was checked October 22: Xcode 27.1 lists iOS 17+ simulator support. The current helper selects simulators explicitly; a physical iOS 17 device does not silently satisfy its role without an intentional adaptation. Current-OS checks cannot substitute for minimum-OS acceptance.

## Bounded performance session to prepare

For each actual phone/tablet, record exact source/build/dirty inputs, OS, display cadence, power/charging and ambient conditions, settings, duration and tool overhead. Proposed initial scenario: two minutes of warmup, eight minutes of dense play, three minutes of mixed-map navigation, then two minutes of Settings/background/resume. Record deviations and legitimate loss/replay; do not keep a terminal board alive through hidden mutations. Run a separate short quiet-motion comparison rather than quietly replacing the sustained normal-motion session.

Reuse the existing 49-cell `ObservatoryReviewFixture`, `RestorationInteractionScenarios` native controls and `WorldMapReviewFixture` mixed repair states. Preserve their reset-only isolated defaults; normal player saves are not fixtures. Any original-phone delivery still requires separate authorization and `scripts/device-update.py`.

Start with a broad Game Performance Overview trace and narrow the next profile only when an observed uncertainty warrants it. Apple's [handheld performance session](https://developer.apple.com/videos/play/meet-with-apple/242/) recommends diagnosing realistic sustained behavior. These proposed durations bound the first sample; they do not establish hours-long stability or human comfort.

| Budget / measure | Before judging a result |
| --- | --- |
| Frames | Derive the frame budget from the selected device/app display cadence. Report interval distribution, missed deadlines and event-correlated stalls; keep warmup/loading separate. No universal 60/120-FPS promise is introduced. |
| Input | Preserve the existing ≥0.5-second readiness assertion only for its exact `NativeInputWindowTests` seed/phase sample. Other human decision windows need their own observations. |
| Memory | Record prewarmed repeated-loop trend, allocation peaks and unexplained retained growth. Nominal material/raster bytes are not process/GPU residency or a physical RAM ceiling. |
| Energy / thermal | Record available counters, thermal/charging/tool conditions and unavailable metrics. Characterization may remain Unknown against an unset numerical product budget. |
| Adoption | Freeze any proposed measured budget before judging a later optimization. Do not retrospectively call the baseline a pass by choosing a threshold around its result. |

## Prepare the named readability states

| Risk state | Existing owner / reproducible preparation |
| --- | --- |
| Warm Sunwheel controls / 75% outlet | Retained source-bound phone and dense landscape tablet images identify regions. HUD/theme/restoration/artwork owners are unchanged from `d057696` in this bounded query, while map assets changed separately; complete relevant-input parity must still be checked before adopting old pixels. |
| Kite 75% sail/star cue | Historical captures identify the region; current UI/artwork owners differ from the recorded source, so refresh the composite. |
| Seed 25% root/pearl cue | Some original exports are absent. Use the existing `--seed-restoration-review=5` fixture; do not reconstruct missing pixels. |
| Silver early pool / bright “Next shower” | Existing `--silver-restoration-review=5` and `=14` fixtures support refreshed current composites. |

Fixture scores 5/9/14/18 represent painting milestones 25/50/75/100; displayed progress is 28/50/78/100. Preserve that distinction. Existing tablet scenarios cover both orientations and milestones; select only the named risk states for this leaf.

The [UI system](../../design/GAME_UI_SYSTEM.md) proposes 4.5:1 for ordinary essential text. Define actual foreground/backdrop pairs before measuring translucent text/shadow. Anti-aliased glyph edges and adjacent scenery in a flattened PNG alone do not establish the hidden backdrop. Such samples remain diagnostic. Physical cue recognition needs actual people, display/ambient conditions and assistance records; simulator screenshots cannot close it.

## Continuing run and worker discoveries

Readiness findings are preserved in this record and linked from their issues. #206–#209 retain their actual acceptance. #210 waits for the uncoached study decision; teaching first would erase the intended baseline. Independent software work and discovery continue under the [factory contract](../../AGENT_FACTORY.md#keep-useful-work-discoverable).

The preparation also found that the older `docs/PLAYTEST-FALLING-SKY.md` current section still describes automatic aging/implosion and its lower section historical 18-light First Light. Treat those as stale/historical guidance, not current revision-3 instructions. The new observation packet uses current owners; a separate bounded documentation correction can retire misleading present-tense statements without rewriting historical results.
