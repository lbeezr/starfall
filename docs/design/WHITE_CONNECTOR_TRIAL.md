# Test an exclusive white connector

**Status: Accepted for bounded rule experiment · Owner: current implementer · Date: 2026-10-17.** The user asked to examine pressure, clever setup/hold timing, rewarding clears and replayability as separate axes, and authorized exploring another star when it creates a useful strategy. First test one white-star role in deterministic fixtures; do not add it to production showers or combine it with storms/constellations yet.

## Hypothesis and rule

A white star can connect separated stars of the chosen ordinary family. Tap a colored star to choose that family. Flood only through that family and orthogonally adjacent white connectors; other colored families and dark stars do not join. White counts as one starlight and is consumed with the group. It never grows. Tapping white alone does nothing. Existing three-starlight eligibility, dark removal beside any cleared cell, settling once and deliberate next clears remain.

One white star may belong to more than one eligible family group, but a clear spends it for exactly one. Holding can preserve another connection; using it now can free a threatened column. This makes the shared resource and alternative visible without another gesture, charge meter or mode. It is a candidate, not a selected wildcard/bomb/scoring system.

## Acceptance before implementation

- Two different families can each have a legal group sharing one connector, without mixing the families. Each reported legal group's first cell remains a valid colored tap anchor; no duplicate group/white-only clear.
- Consuming a connector removes the competing opportunity. A fixed incoming-star fixture demonstrates a smaller clear protecting a column where the larger alternative loses. A separate low-pressure fixture demonstrates a benefit from holding for growth. Inspect the exact consequences, not just number of possible clears.
- Ordinary-only behavior and encoded replay stay identical to a compiled baseline over a bounded seed/policy sample. Existing package checks pass; white save round trips preserve identity/continuation, old missing fields remain ordinary/dark, malformed light states reject. No preview/RNG changes during a clear.
- White arrivals stack and cannot grow; dark growth suppression/removal, boundaries, invalid taps, full-column overflow and one-time settling retain explicit checks.
- Keep the implementation in a canonical pure-core patch applied to an isolated Git archive, plus focused tests and baseline comparison tooling. Production app/core, generator, saves and assets remain unchanged. No natural spawning, new UI gesture, campaign, economy or monetization.

Layout-only unit fixtures use the existing internal board initializer and are not restorable game saves. Save tests must start from valid committed arrivals; do not forge saves to admit an authored board.

## Decision point and limits

After the named fixtures, ordinary replay comparison and package/build checks, retain this role only if both immediate-space and held-connection choices have concrete benefits. Otherwise revise/remove the rule before adding presentation or spawn frequency. Passing fixtures establish rule consequences, not understandable or enjoyable play.

A later native trial needs a distinct silhouette/name, family-specific group preview and accessible hints, accurate input/render mapping, ordinary/reduced-motion feedback, interruptions and actual VoiceOver. Use a separate bundle/save contract. The optional encoded light marker is trial-only: an old production decoder could mistake it for darkness, so adoption requires an explicit schema/version contract before any normal save can contain it.

The parallel constellation trial remains an independent candidate. Do not combine rules or infer that more mechanics produce replayability. Human prediction, preference and desire to replay remain separate evidence.

## Native comparison acceptance, before implementation

Build one separate White Connector Lab with a versioned lab-only save key/defaults suite and separate app/test bundle identifiers. Production and constellation apps remain untouched. Use current committed presentation and the existing pure-rule patch. No natural white spawning yet: two selectable examples establish shared-resource choice and visible column pressure. Generate those examples through committed scripted arrivals, not edited JSON or fabricated save counters. Keep the exact next landing hidden in the interface, as in ordinary play; authored known-arrival tests establish consequences but cannot establish player foresight.

Give white a pale body plus a dark interlocking-link symbol, spoken name “White connector”, value one, and an explicit hint to tap a colored neighbor. Show that a colored group's connected value includes its connector and that clearing spends it for that family. Reuse the existing character/material and geometry owners. Never use the Dusk material/name for white. Static screenshots must distinguish the symbol from ready-group circles.

Verify both examples and their alternative branches in Core; native taps must match committed values and prevent rapid double input. Verify save/relaunch, background/resume, menu dismissal, example replacement during a pending clear, restart and stale callbacks. Inspect normal animations separately from quiet/VoiceOver paths. Run package tests, focused hosted/UI tests and Debug/Release simulator builds; inspect ordinary and largest-text captures. Actual VoiceOver must speak and activate a colored anchor and explain white. Record any unexecuted cases explicitly. No physical-device or enjoyment claim follows from this test.

Decision point: after this native check, a simulated player should predict which family consumes the connector before tapping and explain what alternative was lost. Retain for uncoached human comparison only if the visual/spoken identity and this consequence are understandable. Fix or remove the candidate if these fail; do not tune spawn frequency before that decision.

## Native decision point outcome

[Two decisions per example](../evidence/white-connector-native-2026-10-17/predictions.md) support retaining the candidate for a bounded human comparison. The familiar simulated player predicted consumption correctly and chose aqua before the independently clearable rose pair. This is an ordering benefit, not two mutually exclusive rewards. No concrete hold benefit was observed by that player. Clarify white's value-one contribution before cold testing; keep natural spawning absent and retain the current source pin until that comparison or a deliberate rebase/removal.

## Main-review decision

After the native fixture decision, main `2b936ec` confirms the user-selected traced-subset mechanic alongside ordinary taps. Close this ordinary-only fixture study and park white. Its consumption and ordering evidence is retained, but no immediate human test of the older full-game boundary is planned. First assess which stars a player chooses to trace/preserve under the selected rules; then explicitly adapt or remove this candidate. Keep one phone lab and production rules/saves intact.
