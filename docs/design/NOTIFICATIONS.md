# Optional weekly reminder plan

**Status:** Accepted plan; implementation deferred · **Owner:** Current implementer · **Updated:** October 17, 2026, Eastern time

Starfall should stay quiet unless a player asks for a reminder. Start with one optional weekly play reminder at a player-selected day and time. There is no time-dependent reward or unattended sky emergency that needs an alert.

**Decision:** Plan one local weekly reminder, off by default. Do not implement notifications in this batch. The user accepted this direction on October 17, 2026.

**Next action:** Keep implementation deferred until requested. When that work begins, implement only the weekly reminder and verify the acceptance criteria below before shipping.

## What the player experiences

A player opens reminder settings, sees a sample message, and chooses a weekday and local time. Only an explicit enable action requests iOS notification permission. No permission prompt appears on first launch or after an ordinary round; declining does not affect gameplay or trigger repeated requests.

Example copy: **Starfall** — “A quiet moment among the stars?” This is proposed wording, not an implemented notification. Avoid guilt, streak pressure, invented scarcity, or claims that a saved sky needs saving. Nothing progresses while the player is away.

The reminder is weekly even if the player has recently played. It is a chosen schedule, not an inactivity campaign. Off cancels pending reminders. Editing the schedule replaces the previous request. Opening a reminder lands at Welcome/Resume and waits for the player to begin; it never starts showers automatically or resets the saved sky.

## Scope and boundaries

- One reminder mode and one pending recurring schedule, with at most one scheduled reminder per week. No requested sound, app-icon badge, Time Sensitive classification or urgency.
- Use Apple's local notifications; no custom server, remote push service, analytics, tracking or external SDK. Keep reminder preferences separate from core game saves and deterministic rules.
- Respect system permission, Focus and delivery settings. A chosen time is a delivery request, not a guarantee. If permission is denied or later revoked, settings must explain that reminders cannot be delivered and offer a user-initiated route to system settings.
- Interpret the selected weekday/time in the current local time zone. Avoid duplicate scheduling on relaunch, rapid edits, background/resume or notification opening. Verify daylight-saving and travel behavior before release, including ambiguous or nonexistent local times; do not issue catch-up alerts.
- Keep permission callbacks and scheduling completion ownership explicit. Off or a newer edit must win over an older in-flight enable request. Notification handling belongs in app coordination, outside StarfallCore, and must preserve the existing pause/resume contract.

## Other message types

| Message | Decision |
| --- | --- |
| Inactivity reminder | Deferred. Consider one optional reminder after a week away only if playtesters want it; no repeated ignored-message campaign. |
| Friend passes a score | Defer custom alerts. Verify Apple's Game Center experience first to avoid duplicate notifications. |
| Global ranking drops | Excluded: frequent changes rarely justify interruption. |
| New features or announcements | Prefer a short dismissible note on a later app opening; no notification announcement system in the first scope. |
| Guidance and results | Keep inside the game using existing presentation boundaries; avoid interrupting active play. |

These decisions do not add events, daily rewards, progression or a messaging inbox. Optional rankings remain outside this reminder scope.

## Future implementation acceptance

All items below are **not run**; this document accepts the plan only.

- [ ] Fresh install is silent, with reminders off and no permission prompt. Enabling shows the preview and requests permission only in context; denial leaves the full game usable.
- [ ] Selecting a weekday/time creates exactly one weekly schedule. Relaunch and rapid edits do not duplicate it; Off removes it, including when permission/scheduling callbacks arrive late.
- [ ] Permission revocation and re-enabling through iOS settings produce accurate app settings, without repeated prompts or stale pending requests.
- [ ] Physical-device delivery and opening work with the app foregrounded, backgrounded and terminated. Foreground play receives no interrupting reminder banner or sound. Focus/delivery delays are documented separately from scheduling correctness.
- [ ] Schedule changes, travel, daylight-saving transitions and missed delivery do not cause duplicate or catch-up alerts. Record actual platform behavior and resolve discrepancies before release.
- [ ] Notification opening preserves committed saves, scores and pause state, presents Welcome/Resume, and waits for explicit Begin/Resume. Rules, RNG and save compatibility remain unchanged.
- [ ] Reminder controls reflow at large Dynamic Type and expose native labels/values to VoiceOver. Check permission return and settings dismissal. Follow the [development/RC accessibility cadence](../DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage), with actual VoiceOver acceptance at the release candidate.
- [ ] Focused scheduling/cancellation tests, affected hosted/UI tests, core tests, hygiene checks and simulator builds pass. Device delivery remains separate evidence. Inspect the settings and notification appearance; no new gameplay animation is planned, and existing full-motion/Reduce Motion behavior must remain intact.

Judge usefulness through playtester feedback about timing, wording and control. Opening rates alone do not establish a welcome reminder; this plan adds no telemetry.

## Research and unresolved limits

Apple recommends relevant notifications and contextual permission requests: [notification design guidance](https://developer.apple.com/design/human-interface-guidelines/notifications) and [asking permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications). [Local scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) supports the proposed server-free scope.

Apple's [leaderboard documentation](https://developer.apple.com/documentation/gamekit/encourage-progress-and-competition-with-leaderboards) describes friend score notifications. Starfall's live delivery, availability and interaction with player settings remain unverified; this is not a promise that our current rankings integration delivers them.

The weekly cap, silent presentation and chosen copy are Starfall product decisions, not measured optimal frequencies or Apple requirements. Human preference, actual notification delivery, accessibility and visual acceptance remain unverified. This text-only plan introduces no UI or artwork; screenshots would not establish the proposed behavior.
