# Local Starfall improvement wave — October 16, 2026

Three disjoint agent lanes worked in the existing checkout using the configured priority (Fast) service tier. Existing artwork, HUD, backdrop, refill mapping and tests were retained and integrated. The user requested incremental integration; verified work is recorded in six scoped local `main` source/CI commits plus a separate evidence checkpoint. Other chats' unfinished research and audio work remain outside these checkpoints. The configured command-line Git account was denied write access to the remote; no remote branch was changed by this wave.

| Owner | Responsibility |
| --- | --- |
| `experience` | Shared design system, menu, HUD, results, Settings and accessible board |
| `renderer` | Jewel presentation, previews, bounded effects, survivor gravity and new arrivals |
| `core_reliability` | Deterministic rules, save validation, canonical groups and CI coverage gates |
| Root integration | Store/feedback boundary, native UI tests, independent review, integration and evidence |

## Delivered behavior

- Canonical deterministic matching groups support a native VoiceOver rotor while retaining every board cell for spatial exploration. Save validation rejects impossible score/move combinations.
- Play/Continue is prominent, a saved round has a concise summary, and terminal rounds show an inline result card and a clear replay action.
- The presentation lane owns a shared design system: semantic color, typography, spacing, radius and layout tokens; common action, panel, status, title and progress primitives; and consistent native control states across menu, HUD, results and Settings. Its reference lives in `docs/design/DESIGN_SYSTEM.md`.
- Holding a valid group gives a still preview; dragging to another cell cancels it. Invalid taps remain free. Default clear sparks and arrival trails have explicit caps.
- New refills arrive diagonally from the upper/right board edge; surviving jewels fall vertically from their true source cells. Free recovery replacements appear in place. All are presentation-only and reuse the bounded material factory.
- Menu, Settings, resize and scene detachment settle an in-flight turn to the saved committed state. Stale callbacks cannot unlock a newer turn or announce an interrupted result.
- Device feedback lives outside SpriteKit: existing optional sound, gentle successful-turn haptics and settled VoiceOver announcements. Calm effects/Reduce Motion suppress motion and haptics.
- Settings uses a scrollable layout with native toggles and uncapped Dynamic Type. Apple's clipping audit remains part of native acceptance rather than being suppressed.
- CI runs the complete UI and hosted test targets, derives expected test counts from source, and checks the named screenshot contracts.

The 7×7 board, five jewel types, orthogonal groups of 3+, 70-jewel target and 18 valid moves are unchanged. The pre-rendered five-piece artwork stays DEBUG-only. No purchases, ad SDKs, tracking, accounts, network service or progression was added.

## Validation

Completed on Xcode 27.0 / iOS 27.0 Simulator, iPhone 17 Pro (402 × 874 points), at 2026-10-16 19:06:44 UTC.

| Check | Result |
| --- | --- |
| Deterministic core (`swift test`) | 27 passed, zero failures |
| Hosted app/renderer tests | 34 passed, zero failures/skips |
| Native UI flows | 10 passed, zero failures/skips |
| Complete native suite | 44 passed in one run; `native-summary.json` |
| Follow-up screenshot timing check | 1 focused UI test passed; `footer-evidence-summary.json` |
| Isolated integration checkpoints | Design-system foundation builds; renderer builds and all 34 hosted tests pass from committed snapshots |
| Release simulator build | Passed; bundled privacy manifest matches source, AppIcon metadata present |
| CI source checks | Shell syntax and all 11 embedded Python blocks compile; source-derived gates expect 10 UI and 34 hosted tests |
| Screenshot contracts | All 30 required native captures found and SHA-256 recorded; eight passing captures retained plus the unresolved medium-sheet audit screenshot |

The UI flows deliver real board taps, a rapid double tap, a cancelled drag, free invalid taps, menu/continue, restart, saved-game relaunch, settled background/resume, Calm Effects, five DEBUG artwork families, and win/loss restoration. The last-move win uses a real final tap and preserves the truthful 73/70 score with zero moves while progress caps at 70. Hosted tests separately cover interruption and stale callback boundaries; they do not establish physical timing or motion quality.

Native audits retain `textClipped`, `sufficientElementDescription` and `hitRegion`. They pass the tested menu/game largest-text positions, expanded normal-size Settings and maximum-size Settings with the footer fully visible. The actual 49 accessible board controls clear valid groups and explain invalid groups. Modal tests verify gameplay leaves the accessibility hierarchy while Settings is open and returns after dismissal. See the limits below before interpreting these results.

The only change after the complete native suite moved one screenshot before its audit (which can change scrolling) and corrected a diagnostic comment. Its focused test passed; production code and assertions are unchanged. Both test-source hashes are retained.

`source-and-product.json` records 42 source/config/asset hashes, the base/runtime commits, integration checkpoints and Release product checks. `screenshot-manifest.json` records all 30 native attachments and the eight retained captures. The result bundle is `/tmp/starfall-swarm-accepted.xcresult`; logs are `/tmp/starfall-swarm-accepted.log`, `/tmp/starfall-design-final-core.log` and `/tmp/starfall-design-final-release.log`. Temporary bundles may be removed later; the compact summary, hashes and selected images are retained here.

Independent source review covered the design-system boundaries, store feedback, renderer integration and modal accessibility boundary. A separate visual review inspected gameplay, both Settings sizes and the last-move win: no obvious overlap was seen, but that does not overrule the unresolved native audit.

## Limits

The initial medium-height Settings sheet still has an unresolved native `textClipped` report, despite readable text in its screenshot. The normal-size passing audit expands the sheet first; maximum-size audits reveal the last footer paragraph first. These are specific tested reading positions, not a medium-detent pass or proof that the earlier reports are false. See `known-settings-medium-issue.txt` and `screenshots/known-settings-medium-issue.png`. All three audit types remain enabled and every reported issue fails its audit.

Native accessibility-control and audit tests do not establish spoken VoiceOver focus/rotor usability. Haptic feel, audio quality, physical-device performance and human play balance require separate hands-on checks. No physical-device or App Store distribution claim is made.

This wave's complete native run targets iPhone 17 Pro on iOS 27.0. Minimum supported iOS, narrower iPhones, iPad, keyboard focus and Increase Contrast need separate coverage. Calm Effects and controlled reduced-motion settlement are covered; actual system Reduce Motion operation is not established by these tests. No remote CI run was dispatched for this dirty working tree.
