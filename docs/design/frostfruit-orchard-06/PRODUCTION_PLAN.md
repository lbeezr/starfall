# Deliver Frostfruit Orchard as the sixth restoration

**Status:** Development-verified and delivered · **Owner:** Current implementer · **Updated:** October 20, 2026
**Starting source:** main `d0dfcc1`

Frostfruit Orchard should give the player a distinct achievement: a silent winter gathering place regains its luminous fruit, and the last closed cluster opens. Deliver five complete paintings for iPhone, iPad portrait and iPad landscape, integrate the sixth ready location into the existing local journey, verify the normal app, and ship current main through the canonical updater.

**Next action:** Complete physical-play and actual VoiceOver/full release-candidate acceptance separately from this delivered development build. The [development evidence](../../evidence/frostfruit-orchard-2026-10-20/README.md) owns combined inputs `6aee65e` / `dev.bd94e46b80` and passing 342 hosted, 6 phone, 3 tablet and 2 compact-phone checks, plus Core and Release. Pre-integration tests, failures and corrections remain historical evidence. Merged in [PR #187](https://github.com/lbeezr/starfall/pull/187); the [canonical receipt](../../evidence/frostfruit-orchard-2026-10-20/delivery.json) verifies `dev.bd94e46b80` installed from main `3f560e2` in the original iPhone app. Main CI was pending at installation. Installation is separate from physical-play and actual VoiceOver acceptance. The [art brief](BRIEF.md) owns composition and restoration beats.

## Scope and observable acceptance

- [x] Select a native-fit master for each family before deriving its earlier states: phone 06, portrait 07 and landscape 03. The [family provenance](BRIEF.md#three-views-of-the-same-orchard) records the selected attempts and review limits.
- [x] Verify that all fifteen selected paintings preserve the approved orchard identity and the connected-place richness of Lantern Landing and Ribbon Crossing after packaging. Each family keeps registered camera, structures and backdrop through scores 0/5/9/14/18.
- [x] The first translucent fruit is visible at 25%. At 75% the high cluster is closed; at 100% it has a clearly open silhouette and a few released seeds. Snow and frost remain part of the healthy final scene.
- [x] Masters and all states work with unchanged actual star scale and hit geometry at sparse and full occupancy. No center mask, cleared rectangle, painted character, grid, control or text is introduced.
- [x] Existing current challenge actions, seed-42 supply, 18-light target, committed win, overflow, light transfer, whole-image transitions and ordinary result remain the gameplay contract. No dark-star obstruction, new harvest rule, audio subsystem, Murk performance or traveler animation is added.
- [x] Frostfruit Orchard uses its existing world identity and damaged/restored map region. A valid Silver Pools completion exposes the newly ready sixth location; existing saves retain access to the original five without fabricated completions. Unbuilt successors remain unavailable.
- [x] Preview and cancellation preserve the retained round; Begin alone starts the selected location. Win, interrupted progress, resume, relaunch and explicit replay retain the correct challenge identity and world completion.
- [x] Core and hosted checks cover readiness, progression and saved compatibility at the responsible owners. Practice still writes neither a normal round nor world completion.
- [x] Native interaction and inspected captures cover all fifteen scenes, representative dense input, phone and both iPad orientations, rotation, compact and maximum text, Entry/results and map return. Readable control surfaces and restoration cues are judged together.
- [x] Shared terminal reading surfaces keep both win and overflow headings and result text/actions readable over the retained final board. Verify immediate Replay/World Map access, restored-landmark clearance and maximum-text reflow without changing active play or the paintings.
- [x] Normal-motion completion is inspected in a recording; native interaction checks cover interruption and resume. Stills and Reduce Motion remain separate evidence. Exact source/build, configuration, dirty inputs and failed or missing checks remain visible in evidence.
- [x] Repository hygiene, whitespace, affected Core/hosted/UI checks, Debug/Release builds and resource membership pass under the [verification matrix](../../ENGINEERING.md#verification-by-change).
- [x] Publish and merge the verified source, artwork and evidence, then verify installation in the original app through `scripts/device-update.py`. Preserve player data and use the [wireless delivery check](../../../scripts/README.md#wireless-delivery-check) if the paired phone's tunnel is idle.

## Work and ownership

| Batch | Owner | Exit |
| --- | --- | --- |
| Brief and source reconciliation | Documentation owner with root | Current map, Observatory UI and journey contracts are reflected; exact source and visual uncertainty are recorded. |
| Masters and state production | Root / assigned art owners | Native sparse/full master review precedes derivation; all fifteen selected paintings and attempts have exact provenance. |
| Shared integration | Root / assigned implementation owner | Sixth content registration, shared presentation and copy, saved identity and progression checks use existing owners. |
| Native and development verification | Root, with independent visual review | Source-bound checks and captures establish the acceptance above; concrete remaining physical/RC limits are recorded. |
| Publication and delivery | Root | Published tree reconciles with tested source, merged main installs through the updater, and the sanitized receipt links the exact build and source. |

## Hypothesis and adoption point

The bounded art hypothesis is that the kit's 55° overhead construction guide can preserve a rich, believable orchard while making its fruit restoration readable beneath current native UI. The guide was applied to prompts and reference selection; native fit approval is qualitative and does not prove a measured 55° projection in the generated artwork. The three completed masters passed composition review against actual native stars. Combined sparse/full state checks preserve that fit; do not compensate for a failure by moving cells, shrinking stars or introducing a clearing mask.

The three masters were accepted before state derivation; all fifteen final paintings are now adopted in the normal app. Failed attempts and temporary master-probe history remain documented provenance, with no alternate player route or runtime art pilot. The [experiment register](../../EXPERIMENTS.md) records adoption; [development evidence](../../evidence/frostfruit-orchard-2026-10-20/README.md) owns native scope. Publication and installation are verified, and deferred concrete corrections belong in [ENGINEERING](../../ENGINEERING.md).

## Shared result-contrast correction

Dense native result captures exposed bright retained stars behind the title and paragraph. Inspection traced the problem to shared `SkyFlowCeremony`: the Observatory integration removed the former local heading backing and protected result dialogue. Retaining the committed final board is intentional under the [flow contract](../SCREEN_FLOW_POLISH.md#results-visuals-and-accessibility).

The integrated result presentation uses Observatory's vertical `ViewThatFits`: the scenic composition first, a compact fallback without decorative cast or restored-scene clearance next, then scrolling when necessary. Local `starfallPanel` surfaces protect headings and text/actions. `resultContent` places actions before decorative cast, while the primary World Map action and adaptive secondary action row keep their incoming Observatory hierarchy. This preserves committed rules, saves and all fifteen paintings. The compact Replay failure at `bede49c` and narrow fix at `f7b5c71` remain pre-integration history. The [evidence record](../../evidence/frostfruit-orchard-2026-10-20/README.md) records fresh combined-source checks at `6aee65e` / `dev.bd94e46b80`; earlier result captures cannot certify the merged presentation. Measured contrast, actual VoiceOver and physical gameplay remain separate.

## Risks and current limits

Master revisions resolved observed HUD/crown and terrace/cast collisions; the adopted sources preserve that composition through all five milestones. Native stills, transitions and local result backings have separate source-bound evidence. Sustained physical-device comfort, measured contrast and full release-candidate/actual VoiceOver acceptance remain open.

The atlas's dark-star obstruction and Murk reaction remain story/gameplay proposals. This batch uses current actions and still paintings; their presence in historical world data is not authorization for an additional mechanic or cutscene. Existing map paintings already contain the orchard; no map repaint is planned.

The [consolidated provenance](art-prompts.json) and [selected asset manifest](production-assets.json) identify source selection and the limited native master reviews. These planning documents do not establish final Core, hosted, UI, build, animation, actual VoiceOver or physical-device acceptance. The source-bound verification record and canonical installation receipt are linked above; physical-play and actual VoiceOver acceptance remain separate.
