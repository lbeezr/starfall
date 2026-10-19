# A short follow-up input buffer

**Status:** Accepted for implementation · **Owner:** current implementer · **Updated:** October 18, 2026

Fast players should see a valid next tap or swap register while its stars finish moving. Keep one pending action for at most 650 ms, acknowledge it immediately, and execute it once when its required columns become available. This covers ordinary 340 ms swap/fall and 560 ms clear presentations; the initially proposed 250 ms would reject their early follow-ups. This is a separate delivery after the [immediate-swipe foundation](IMMEDIATE_SWIPES.md).

**Next action:** verify the contract below before merging and canonical delivery. The duration is an initial tuning value, not a measured optimum.

## Acceptance before implementation

- A valid tap or cardinal swap on the committed board can wait behind presentation without changing score, stars or saves until it commits. Unrelated ready columns still act immediately.
- The pending action records actual star identities, expected neighbor and the committed board snapshot. It never retargets a replacement star or a changed board. Core validates legality again when presentation permits admission.
- One latest intent replaces the previous one. New physical contact cancels the old pending intention before it can execute under the new finger. No multi-move queue or timer-driven catch-up is created.
- A bounded board cue and readable acknowledgment distinguish registered input from rejection. Completion executes once; expiry clears the cue and gives visible cancellation feedback. Normal/quiet modes preserve outcomes.
- Pending input owns a bounded clock hold; releasing the physical contact cannot lose it, and expiration/cancellation releases it without adding grace time. Already-due rain retains priority.
- Settings, background, resize, scene detachment, restart, new game and incompatible board changes cancel the pending action and deadline. Nothing transient is saved or replayed on restore.
- Native and accessibility tap/swap entry points use the same request boundary. Held constellation paths retain their exact-selection contract and are not buffered.

## Verification

Use deterministic presenter/clock cases for completion order, replacement, expiry, disappearing/replaced star, ready independent actions and lifecycle cancellation. Exercise production physical sampling with a real SpriteKit host for rapid follow-up motion, then native gestures, largest text, settings/background and full/quiet outcomes. Record committed-source hashes and canonical installation identity separately from physical comfort. No new dependency, save schema, rule or app target.
