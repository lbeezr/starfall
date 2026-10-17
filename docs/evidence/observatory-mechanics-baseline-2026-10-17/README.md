# Observatory baseline for mechanics alignment — 2026-10-17

The user requested a main review before further mechanics work. Committed main had advanced to 9bb008d through publication/merge records; current app work also included staged and unstaged Observatory geometry, environment, HUD/menu, guide and feedback changes. Frozen mechanics labs use 30af812, and the compact HUD overlay uses be4d869. Those are not current-interface acceptance evidence.

Created an immutable snapshot with the existing tools/environments/prepare-observatory-review.py exporter, after cf603b1 recorded the completed frozen-HUD comparison. No changes to production source, candidate rules, dependencies or normal saves. The captured source includes the actual working-tree Observatory, not just committed HEAD. Immediately after export, runtime/build/test file hashes still matched the worktree. source.json records hashes, staged/unstaged status and any subsequent source drift; the raw full export manifest stays with the temporary snapshot.

XcodeBuildMCP build_sim(buildForTesting: true), Debug, shared Starfall scheme, iPhone 17e / iOS 27.0 (24A434), simulator A84C81F5-AE41-496A-97AE-E17C63E18D29, Xcode 27.1 (27A9275), CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES: **passed, zero reported warnings/errors**. App and both native test targets compile, including the actual VoiceOver-service test. Derived data /tmp/starfall-current-mechanics-baseline. Exact build log and test-product paths are in source.json.

This is compilation evidence only. The prototype bundle was not launched or installed for this check, so normal simulator game data was not reset. No current-baseline interaction, actual VoiceOver speech, visual/motion, device or Release result is claimed. Existing test products must not be run against normal saves without isolating the app bundle/defaults first. Hygiene and diff checks passed for the evidence batch.

Implications for the next mechanics trial:

- Retain deterministic shower/save findings: production core changes since the frozen pin are naming/documentation only, and no working-tree core changes were present at review.
- Use this source-bound Observatory family for presentation and input acceptance. Renderer points and native cells now share ObservatoryGeometry; old rectangular-board tap/visual results cannot accept that projection.
- Compose phase information with the existing trail and guide roles; preserve quiet active play rather than restoring old status/forecast rows wholesale. The simulated HUD feedback preference needs a fresh check in this interface.
- Reuse the current actual VoiceOver-service test boundary for spoken transition/focus checks. Earlier policy tests only verify announcement selection.
- Keep any candidate export isolated from normal saves and production generation. Match reference/candidate presentation and document subsequent source drift; compile success is not mechanics or gameplay acceptance.

The separate unfinished user phrase was explicitly withdrawn (“ignore that for now”). Main alignment remains the active direction; no production phase adoption is implied.
