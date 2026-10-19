# Restore Seed Moon in the regular app

**Status:** Implemented and development-verified; publication and delivery pending · **Owner:** Current implementer · **Updated:** October 19, 2026

Add **Seed Moon** as the fourth directly selectable 18-starlight challenge. Keep the same seed-42 opening and rules as First Light, Ribbon Crossing and Kite Harbor. Restore a seed inside a cracked moon through five whole-image paintings per viewport: a root lights, the shoot rises, leaves frame a closed bud, and the final bud opens into a sheltering canopy.

**Next action:** Publish, merge and canonically deliver the verified runtime `b77a100` / `dev.545382e6f6`; final test-only checkpoint `124fd21` passes focused overflow, compact and Release checks. Only the phone 50% painting changed from `a0c7360`; [current evidence](../../evidence/seed-moon-2026-10-19/README.md) records source-bound hosted, phone/tablet, density and motion checks. Core owns the win; the existing light transfer, whole-image crossfade and ordinary result present it. No campaign, unlock, gardening mechanic, scenery travelers, added unfolding animation or cutscene. Future user-generated clips may show inhabitants resting beneath the canopy; none are implemented here. The [atlas](../WORLD_ATLAS.md#04--seed-moon--enough-light-to-make-shelter) owns the place; [world-data.js](../world-01/world-data.js) owns the five authored beats.

<img src="../world-01/map-v1.png" width="540" alt="Approved twelve-location concept map with Seed Moon numbered 04: a green shoot rises from a pale split round shell above a small stone garden">

**Approved generated map concept — not runtime evidence.** Inspected October 19, 2026; [original artwork and provenance](../world-01/README.md). Keep the split round base and living green shoot recognizable. Tiny map inhabitants are not baked into the scene paintings.

## Scope and observable acceptance

- [x] Welcome and the normal menu offer Seed Moon directly, with named Entry, Help, result and replay. All four challenges retain seed 42, the fixed opening, steady showers, 18-light target and existing overflow rule. Open sky stays the default; no campaign progress, unlock, extra currency or new growth/scoring rule.
- [x] Core owns committed progress and outcome. Scores 0/5/9/14/18 select 0/25/50/75/100 artwork; text reports actual clamped progress, including overshoot. Reaching 18 commits the win independently of animation callbacks.
- [x] Existing survival and all three challenge saves retain board, score, preview/RNG, pause and generation behavior. Seed Moon round-trips through validated saves. Pending Entry/replay previews zero without replacing the retained round until Begin; cancellation resumes it. Pending Open sky selects ordinary scenery.
- [x] Phone portrait, iPad portrait and iPad landscape each have five bespoke views of the same Seed Moon. Each frame is one continuous proportion-preserved painting: no center mask, clearing patch, spatial fade, cut line or separately positioned image regions. Roots and leaves stay outside the active star silhouettes; no game pieces or faces are baked into scenery.
- [x] Each family preserves the shell outline/cracks, ledge, root routes and plant position. Recovery is cumulative: the first root stays lit, connected roots stay connected and risen growth stays present. At 75% the central bud is visibly closed; at 100% it opens into a canopy with a readable protected space beneath. The shell remains the landmark; restoration does not destroy it.
- [x] All fifteen native states are visually inspected with readable HUD and controls. Sparse and crowded samples keep the seven-column field and cast distinct. Real clears pass on phone and both tablet orientations; rotation preserves state/identity and restores cell geometry. Largest text reflows; inspect compact portrait and report any unsampled orientation. Dense input is verified separately from dense appearance.
- [x] Normal finishing light reaches a registered plant focus before the existing result handoff; the complete-image transition reveals the canopy. No separate leaf-unfolding subsystem, tiny walkers, arriving residents, new particles or world-travel sequence. Native playable stars and the existing ceremony cast retain their roles.
- [x] Existing bounded feedback/lifecycle behavior remains valid. Calm effects/system Reduce Motion and interrupted/restored states settle to the same committed result. Background, settings, restart, replay, rotation and scene replacement reject obsolete work. A restored completed save shows its canopy without an unearned ceremony.
- [x] Focused Core/save, hosted/native, Debug/Release and resource-membership checks pass. Inspect the fifteen states and a normal-motion finish; exercise representative prior-challenge and Open sky siblings. Record source/build/device, original failures, corrective reruns and residual limits. Actual VoiceOver remains an RC requirement; physical play is separate.
- [ ] Verified changes merge in scoped batches. The canonical updater delivers current main into the original app and verifies installation identity without reset/uninstall; record the receipt and CI status at install. No feature-checkout installation or separate app.

## Five authored beats

| State | Exact authored beat | In-game interpretation |
| --- | --- | --- |
| **0%** | A tightly curled seed rests in a small cracked moon, its root patterns barely visible. | Intact pale shell, sleepy translucent seed and faint existing seams. Ambient sky remains playable. |
| **25%** | One root tip lights and reaches into a seam. | One localized green-gold recovery; the main seed stays curled. |
| **50%** | Roots reconnect below the surface and a shoot rises. | Light follows the established seams; a clear upright shoot grows from the same seed position. |
| **75%** | Leaves unfold around a still-closed central bud. | Supporting leaves open; keep the central bud closed, distinct and visible above the field. |
| **100%** | The bud opens into a glowing canopy with a little sheltered space beneath. | Open upper canopy, warm protected nook and retained round shell. Show shelter through space and light; no added inhabitants. |

The authored puzzle question is **“Use the existing growth rule to make larger stars feel valuable; no new gardening mechanic.”** The fixed round already includes ordinary/grown stars; do not add growth timers, watering, seed inventory or new rule affordances. A future story arrival can follow Kite Harbor; awakened roots point toward Silver Pools. Neither transition is a runtime unlock or traversal.

## Three views of one small moon

| View | Composition and clearance |
| --- | --- |
| Phone portrait | A single split shell and plant occupy the upper scenery, preferably offset from the central HUD. Keep the closed bud/open canopy high enough to read above the board; the shelter opening should be visible beneath it. Use quiet natural navy sky through the playable middle, with foliage/rock only at the margins. |
| iPad portrait | Reveal more of the same round base, resting ledge and a small tended garden at the upper/side edges. Protect the bud from the header and terminal title; avoid an oversized bright leaf spanning the center. |
| iPad landscape | Show wider connected stone ledges, soft roots and neighboring low plants around the same hero shell. Keep the hero bud/canopy in an upper outer quadrant; quiet sky remains continuous across the center. Extra scenery must not become a second seed or competing completion landmark. |

Seed Moon starts **Wild Moons**: pale, softly worn moonstone; translucent mint/green seed skin and leaves; soft roots; restrained opal highlights; violet cloud edges and deep navy sky. Small tending stones, one scoop or a resting ledge suggest care. Root light follows existing cracks rather than shattering the moon. Keep scenery highlights softer than the Crystal Glow cast and keep bright clouds away from lower white controls.

Compose open sky into the original artwork; do not create a digital clearing over a busier scene. Leaf veins, root lines and seams must not resemble legal matching connections. Native `RestorationArtwork`/`RestorationLayout` in the [shared renderer](../../../App/RestorationEnvironment.swift) own fitting and the final light destination. Direct collected light to the pearl seed on phone and tablet landscape. Tablet portrait uses the persistent visible mint root seam below the HUD at normalized (0.160, 0.214), avoiding the partly hidden pearl. Protect the upper closed/open bud with a separate focal region. Exact coordinates belong to the native renderer. Phone sources are 887×1774 pixels and iPad portrait sources are 1086×1448. Landscape sources are 1446×1087 at 0%/25%/50% and 1447×1087 at 75%/100%. The native renderer registers each exact unmodified source size; the reviewer reads natural image dimensions. The [asset manifest](production-assets.json) owns selected file/hash/dimension records.

## Work and verification

| Step | Owner | Exit |
| --- | --- | --- |
| Plan and reviewer | Docs | Observable scope, exact beat text and static comparison using existing cast bodies. |
| Three artwork families | Root/art | Fifteen inspected paintings, stable 75%/100% landmark, preserved prompts and source hashes. |
| Challenge and shared scene | Native owner | Compatible fourth choice, staged entry/save behavior, registered scene focus and focused tests. |
| Acceptance and delivery | Root | Source-bound native/motion/build results, scoped merge and canonical receipt. |

**Observed limits:** the tablet portrait 25% root cue is small beneath a HUD that partly covers the pearl; later shoots/buds/canopies remain distinct. Lower phone white controls cross pale clouds and remain readable in inspected frames, with weaker contrast than the HUD. Final phone 50% raises its shoot above the header. Record native and physical observations separately; still paintings do not verify motion or human comfort.

Core 178/178 and Python 55/55 pass on the dirty source recorded in the evidence report. All fifteen paintings are source-reviewed and byte-identical to their generated sources, preserving the shell/scoop/seed topology and closed 75% versus open 100% bud. Final phone 75%/100% head placement and the later 50% shoot correction address native HUD clearance. The [provenance record](art-prompts.json) preserves all twenty attempts. At `a0c7360`, 329 hosted checks, two phone win/accessibility tests, preview/cancel across all three prior locations and tablet rotation/clears pass; all fifteen native states are inspected, with the final phone50 revision recorded separately. At `b77a100`, Debug, dense 9→13 input, manual overflow and recorded motion pass. Test-only `124fd21` preserves that runtime and passes 12 focused hosted checks plus one overflow/replay UI test, four compact SE3 sibling flows and Release; native-plan/RC-platform checks pass 15/15. Only publication/canonical delivery remains unchecked. Compact coverage is portrait; no independent Seed Moon compact-landscape sample or full RC matrix is claimed. The offline reviewer receives static logic checks only: the earlier local-file browser denial prohibits alternate-route workarounds, so browser rendering remains unverified. Follow the [verification matrix](../../ENGINEERING.md#verification-by-change) and [development accessibility cadence](../../DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage); do not infer physical comfort, actual VoiceOver or human satisfaction from a build or attractive frame.
