# White star and storm production adoption

Status: user-approved implementation, October17,2026. The user said the shared connector seems useful, requested a production-level design/personality/full character, and explicitly requested implementing both white and storms. This supersedes the research-only boundary. It does not establish verified gameplay quality. Implement in the regular Starfall app; no extra phone app, campaign, progression, SDK or backend.

## Lumi: the character who finds connections

Working name: **Lumi**. Warm, attentive and quietly curious; delighted when separate friends connect. Sunny welcomes the player; Lumi helps stars find each other. Lumi notices possibilities without choosing for the player. A small moment of surprise on landing, a hopeful glance when included, and a joyful closed-eye smile when clearing make the rule tangible. No new dialogue system, persistent chatter, unlock narrative or meter.

Identity is under exploration after the user's request for star-symbol research and a potentially round, opaline form. The [new directions and primary-source research](star-cast/white-exploration/README.md) supersede the earlier seven-point character concept as the assumed silhouette. The user selected **Opal Orb**: a smooth round, milky white body with subtle translucent rainbow color suggesting it can join any chosen family. Radiant Pearl and Soft Tri-Star are retained only as possible future design material. The body is packaged through StarCast with authored expressions; fresh app skies now select the combined generation; broader combined acceptance remains open. Keep the warm attentive face and a distinctive one-piece body. Do not lock the name, point count, linked-loop badge or seven-point silhouette. Final material and silhouette must remain recognizable against empty cells, ready rings, Dusk, pale Spark and grown stars at24/36/44pt.

Opal is worth one light, never grows, never changes into another family, and is spent only when included in the committed clear. Start on a colored star: ordinary taps flood orthogonally through that family/white; a trace can use diagonal steps through that family/white and needs five distinct stars. Retracing counts once. Other families remain excluded; white-first/all-white inputs are invalid and free. Dark removal and settling retain their existing owners. Multiple families can compete for one Opal; never imply that white clears all colors at once.

Player explanation: **“Trace blue through Opal, or tap rose with Opal. Either clear spends Opal.”** The user paraphrased that consequence correctly after explanation and visuals, then expressed a preference for the idea. This is informed interest/comprehension, not an uncoached playtest or observed enjoyment.

## Storms: committed shower events

Adopt the existing Surge rhythm: nine ordinary showers, three heavy five-star showers, repeat. Warn one shower ahead; show the remaining heavy count and lighter showers afterward. Phase derives from the committed incoming shower, never animation completion or elapsed wall time. Manual/automatic play use the same sequence. Pause, menu, background and restore retain one deadline; no catch-up showers.

Use calm/recovery wording that describes shower density, not safety. The denser Core sample survived the complete first event without any clears, but8/40 Surge skies ended with a full column versus0/40 Natural. Both blind tester vignettes chose the same clear with/without warning. Storms supply rhythm and accumulating spatial pressure; useful human urgency remains unproven. Do not add a harsher cadence or claim solved difficulty from adoption approval. First Light keeps its fixed18 objective and existing generator; no white or storms in that challenge.

## Generation and persistence contract before spawning

Core must identify the new combined generation explicitly. Decode missing markers as legacy; validate supported versions and legal star roles. Preserve existing board, RNG, committed incoming preview, opening cadence and subsequent legacy generation after restore. Replay retains the saved generation; a fresh survival sky selects the new generation. First Light remains excluded. Define a bounded deterministic white arrival cadence after the teachable opening; choose it from documented seeded samples, not per-frame or UI state. Never replace a committed preview during upgrade.

A white marker encoded into the existing v3 key is unsafe: an old decoder can mistake it for Dusk. Introduce a distinct versioned save envelope/key before normal white spawning. Read/validate old v3 only when no current-format save exists; migrate without altering the committed sky or destroying the old bytes. A corrupt current save must not resurrect a stale v3 sky. Migration is idempotent and never advances RNG/time. Do not import the old white lab saves. Native app identity and the user's current round stay intact.

## Observable acceptance before completion

- Rules: shared family predicate for tap/component/trace; exact spending and competing-group loss; invalid/retraced inputs; dark adjacency; grown ordinary values; white never grows; bounded seeded arrival frequency and opening/First Light exclusions. Regression coverage includes the visible11-versus7 allocation fixture and ordinary-aqua control.
- Replay/save: historical missing markers, malformed/unknown versions and impossible white/dark states; old bytes preserved; valid migrated continuation, replay versus fresh generation, save round trips across phase boundaries9/10,12/13,21/22 and white arrivals. No RNG/preview change during clears.
- Presentation: integrate one identity-aware material owner rather than treating nil as Dusk. Package a clean transparent Opal body; author faces/mark consistently with StarCast. Bounded prewarm/cache and no per-frame image generation/IO. Verify target resources and Release membership. Concept sheet is a construction reference, not runtime atlas or motion proof.
- Native input/lifecycle: ordinary tap and selected trace through Opal, rapid duplicate input, omitted connector, restore/restart/new/replay/First Light, menu dismissal and background during clear/arrival, stale callbacks, manual/automatic phase boundaries and one deadline.
- Accessibility: shared render/hit mapping, stable IDs, full targets, value/name/connector hint, family-specific meaning, non-color identity, phase/count semantics, largest text, Calm effects and system Reduce Motion. Actual VoiceOver must identify/activate a colored anchor involving Opal and navigate phase/guide changes; full RC flow acceptance remains separately tracked.
- Visual/motion: native dense/sparse play, Opal next to Dusk and pale Spark, normal falling/contact/clear animations and quiet modes, readable cue outside playfield, no alert or guide churn. Inspect screenshots and actual normal-motion playback separately. Physical-device acceptance remains explicit.
- Verification: focused Core/hosted/UI checks, `swift test`, Debug/Release simulator builds, source/resource membership, hygiene and diff checks. Record tested source and differences. User preference is recorded as approval of the idea; actual combined play remains a separate test.

Implementation order: versioned Core/generation and regression tests; safe persistence boundary; production character material; shared phase presentation; combined native verification/refinement. Integrate completed batches separately. Retire temporary comparison routing when the regular app is verified; retain source-bound experiment records for reproduction. No new permanent pilot flags.

## Soft character motion

The user requested a squishy Opal, feminine character direction, a teardrop while falling and a softer bounce that differs from the faceted cast. Keep her round at rest. [Motion contract](star-cast/OPAL_MOTION.md) records the bounded deformation and verification requirements. This adds personality through presentation, without a new power or rule.

## Integration with adopted timing

The main-based integration preserves `announcedCycleV1` independently of the new generation marker. Density uses nine lighter showers followed by three heavy showers; brisk timing retains six steady, three faster and three breathing intervals after the opening. These boundaries differ: after shower 12, the next shower is lighter while its interval is still faster. The UI therefore says “Lighter showers,” rather than promising a calmer pace. First Light and historical saved timing remain unchanged.

The store owns one settlement announcement for both axes. Coincident storm entry and the faster warning are spoken together; ordinary automatic arrivals remain silent. Existing generation invalidation rejects stale speech after interruption. The sticky cadence cue retains main’s reserved geometry; the density cue reflows below the playfield at accessibility text sizes. Native acceptance of this combined layout remains required.
