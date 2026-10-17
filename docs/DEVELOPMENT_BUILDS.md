# Identify the build you are testing

**Status:** Accepted · **Owner:** current implementer · **Updated:** 2026-10-17

Use two labels: **`dev.<ID>`** for work in progress and **`rc.1.<ID>`** for a selected release candidate. A correction to a release candidate becomes `rc.2.<ID>`. Keep the ordinary product version, currently `0.1.0`, separate. No beta/nightly channels are needed for this prototype.

The current isolated drawing build is **Starfall Lab · `dev.fecfaa150d`**, numeric build `2`. Its menu shows the ID; [source, checks and installation](evidence/constellation-trace-2026-10-17/README.md) identify exactly what it tested. The lab exporter currently stamps development builds only; selecting a release candidate is a later decision, not an automatic promotion after compilation.

`lab_build.py` fingerprints the exported runtime sources, assets, local core, configuration and project bytes before injecting the ID. Tests and prose do not change the ID; runtime changes do. The full file hashes remain in `CONSTELLATION-LAB.json`. The ID is recorded in `StarfallBuildID` inside the built Info.plist and displayed by the menu. A small input plist supplies the custom key; an arbitrary `INFOPLIST_KEY_*` setting alone did not appear in the generated app and was corrected before installation.

## One current install

Reuse stable app identifiers rather than giving every iteration a new bundle. Updating a bundle replaces its code while retaining its sandbox. This lab continues using `com.starfall.constellations.candidate` and `starfall.constellations.candidate`, despite its new Starfall Lab display name. Never add a new bundle merely to encode a build number.

The user's destination is **one Starfall app** after the update is ready. Until then, retain regular `com.starfall.prototype` with its current round plus one latest lab. The old Control and ten earlier apps were removed from the connected phone/active mechanics simulator as recorded in the evidence. Other named QA simulators and source exports were not erased; they belong to separate source-bound checks.

Before retiring the original installation, integrate the selected rules/presentation into its existing identity, verify old-save and interruption behavior on the exact source, and update it in place. The save must remain committed core state; no lab save should silently replace the player's production round. A successful install or an attractive effect alone does not close the gesture/accessibility gates.

## Accessibility checks by build stage

**Accepted 2026-10-17:** Reserve full actual VoiceOver sessions for release candidates, including the first release. Development builds can continue through gameplay polish and integration with lightweight checks. This cadence governs current work where older engineering notes name an earlier VoiceOver trigger; historical test results remain unchanged.

| Stage | Required scope |
| --- | --- |
| `dev.<ID>` | Preserve accessible controls, labels/values, non-color cues and equivalent committed outcomes. Run affected source, hosted/UI assertions and relevant layout/Dynamic Type checks alongside normal change validation. Enabling VoiceOver, listening to speech and running a full screen-reader playthrough are not routine development or experiment-adoption gates. |
| Targeted VoiceOver work | When fixing a reported VoiceOver defect or explicitly asked to check VoiceOver, reproduce and verify the affected behavior with actual VoiceOver. Keep the session scoped to the defect and related paths; this does not require the full release matrix. Ordinary visual or gesture iteration alone does not trigger it. |
| `rc.N.<ID>` | Run full actual VoiceOver acceptance on the selected candidate before release. Cover the current shipping flows and supported modes, retain source/build/device/OS evidence and resolve release-blocking failures. Automated labels/audits cannot substitute for focus, speech and activation checks. |

For the first release candidate, play a complete round with actual VoiceOver on a physical iPhone: explore star position/type/value, navigate matching groups, select and clear, pause/manual advance, handle arrivals and announcements, reach outcomes/replay, restore a saved round, and enter/leave Settings with usable focus. If constellation drawing is adopted, also verify its accessible select/count/value, release and cancel actions. Include interruption/focus continuity and the applicable Reduce Motion/large-text combinations. Record additional supported-device/layout coverage and any omissions in the candidate acceptance record; do not infer them from one phone.

Carry forward source-bound evidence for unchanged behavior. For later candidate fixes, rerun affected flows and related regression cases; repeat the full session only when changes invalidate its coverage. Identify the evidence used for the final candidate and why earlier results still apply. No release is accepted with required VoiceOver flows untested or known blocking defects unresolved.

During development, record **“Actual VoiceOver: deferred to RC; not run on this development build”** in the relevant acceptance record. Keep known defects and their release follow-up visible; deferral is neither a pass nor a reason to halt unrelated iteration. Routine progress updates need not repeat that planned deferral. Keep normal touch, full-motion, Reduce Motion, automated accessibility and actual VoiceOver evidence distinct; do not disable or weaken existing assertions to satisfy this cadence.
