# Adopt the announced Starfall rhythm

**Status:** Accepted by user; production verification passed; merge/device delivery pending · **Owner:** current implementer · **Updated:** October 17, 2026

Use the previously isolated B cadence in ordinary Debug and Release play. The user explicitly selected B, declined another baseline comparison and requested PR → main → an in-place phone update. This decision authorizes adoption, not a claim of superior enjoyment.

**Decision (updated October 17 after further user feedback):** New brisk skies retain the four-wave opening, then repeat six 2-second intervals, three 1.7-second intervals and three 2.5-second intervals. Earlier V1 skies retain their saved 3/2.5/3.5-second rhythm. Warn one shower ahead. Keep existing wave sizes, generation, single-deadline scheduling and full falling animation.

**Next action:** Verify the promoted production source, merge one PR and deliver exact main through the existing one-app updater. Preserve the phone's current round; it retains its saved timing until a new sky is started.

## Player behavior and boundaries

Core `SkyCadenceID.announcedCycleV2` owns the current algorithm; V1 remains for exact saved replay; new skies persist that version. Count n selects the interval after n committed showers, leading to shower n+1. Counts 0–3 retain the opening. After count 4, slot `(n−4) % 12` selects six steady, three faster and three breathing intervals. Slot 5 warns before the last steady shower. Manual showers advance the same count. Clears, pauses, animation callbacks and wall time do not choose phases.

Older absent-marker and explicit `openingV1` saves retain their exact timing; same-sky replay preserves the saved version, seed, balance and generation markers. First Light remains fixed at four seconds without the opening. Gentle/steady retain selected fixed intervals and suppress phase cues; brisk enables the cycle. New-sky restart preserves a normal round’s selected balance. Leaving First Light for a normal sky restores normal defaults, so the challenge’s fixed four-second/no-dark profile does not leak into survival. Thus an older four-second round needs a new sky and the brisk setting to experience the cycle; do not reset the save silently.

The production view reserves the longest cue's space inside its HUD overlay from the start of a cycle-enabled sky; scenery always fills the window. Phase changes and Settings do not resize SpriteKit or settle in-flight showers. The cue is absent during ceremonies/Settings. Drawing holds the remaining single deadline until release/cancel; it never queues catch-up showers. The calibrated iPhone 17 and 16 Pro Max profiles use the camera margin; unknown/accessible layouts use the header. Native cell mapping and largest-text scrolling need actual tap checks.

The temporary pacing exporter and A/B launch selector are removed. There is one app identity and ordinary save namespace. Test-only clock/observation injection and the offline historical comparison remain development tools; the old fixture name delegates to Core rather than maintaining a second B algorithm.

## Acceptance

- [x] Core exact phases/warnings across two cycles; versioned save/restore/replay and historical-marker coverage; matched-action generation parity.
- [x] Normal app hosted scheduling and native cue checks execute without a B flag/export. Check normal/reduced motion, large text, Settings, native clearing, pause/deadline interruption, restart, background/restore and First Light regressions as affected.
- [x] Normal Debug/Release simulator builds, hygiene, native matrix and explicit target membership pass. No new SDK, backend, account or analytics.
- [ ] PR branch matches the tested tree, main merge is verified and exact merged main is built/signed for the existing phone bundle. Retained round/preferences stay intact and installed fingerprint is checked.

Full actual VoiceOver belongs to RC; this development delivery uses labels/non-color cues and relevant layout assertions. Human preference, accelerated-opening trace comfort, physical smoothness and minimum-OS/tablet coverage remain unverified unless separately observed. Earlier [simulator evidence](../evidence/pacing-acceptance-2026-10-17/README.md) is source-bound; it does not automatically accept this promotion or a device installation.

Production verification and source boundaries: [adoption evidence](../evidence/pacing-adoption-2026-10-17/README.md).
