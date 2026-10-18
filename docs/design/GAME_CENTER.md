# Optional Game Center rankings

**Status:** Implemented locally; live Apple service setup and acceptance pending · **Owner:** current implementer · **Updated:** October 17, 2026

Sky menu → Rankings offers Friends and Global views of an all-time best-score leaderboard. The whole game remains available without authentication, Wi-Fi or cellular service. Game Center is the only online service; no Starfall account, custom server, ads, purchases or analytics are added.

**Decision:** Rank completed standard-balance survival skies by highest starlight. Manual showers and paused clears are allowed, so the board measures score rather than speed. First Light, a run whose balance changed, legacy saves without provenance, and Debug review openings are excluded. Replays are allowed; this is a trust-based casual board, not a competitive anti-cheat system.

**Next action:** User subsequently reported successful Apple Developer Program enrollment. Verify membership activation and authenticated App Store Connect access, then configure the leaderboard below and verify real authentication, friends/global results and offline/reconnect submissions. A signed build was installed and launched on iPhone 16 Pro Max / iOS 26.6.2; user reported offline play works, but live leaderboard setup and sync remain unverified. [Evidence](../evidence/game-center-2026-10-17/README.md) separates local tests from live acceptance. The earlier [ceremony research](RANKINGS_AND_CEREMONY.md) remains a proposal; custom Cups, new trophies and level transitions are not part of this integration.

## Player experience

- Rankings opens inside the existing suspended sky menu. Back, Done and swipe dismissal retain the same pause choice and clock behavior. Signing in is optional; declined/unavailable Game Center leaves every local action available.
- Friends and Global share one classic all-time leaderboard. Up to 25 leading entries plus the player's own entry are shown, with native buttons, named scopes, spoken rank/score and reflow at large text sizes. Authentication uses Apple's controller unchanged. Accessibility-size scope selection uses a menu rather than compressing segment labels.
- Offline, show only the authenticated player's saved standings for that scope, labeled with their update date and a warning that positions may have changed. No cache shows a useful explanation. Signed out shows no cached account rows and offers connection only when a network path is available. Local records remain available.
- A network path does not prove Game Center is reachable. Failed requests retain local saves and pending scores; refresh, foreground and reconnect can retry. A 15-second request deadline stops a stuck spinner and rejects late callbacks. There is no repeating retry loop or effect on the shower deadline.
- The local best and pending upload are separate from fetched rank. A successful upload does not fabricate a new rank: standings must refresh. Cloud save is not provided; the resumable sky stays on this device.

## Ownership and compatibility

`FallingSkyStore` saves committed core state before presentation. Its `SkyRankingSession` sidecar stores eligibility and an undelivered terminal result bound by SHA-256 to the exact saved core bytes. Resetting balance cannot restore eligibility within a run. A new standard sky begins a new eligible session. Existing core save keys and deterministic rules are unchanged. Missing, corrupt or mismatched metadata excludes the run from rankings without discarding the playable save.

A positive eligible terminal result is captured once, with the current Game Center player ID or anonymous ownership, before animation. The pending result is delivered synchronously to the record service and then cleared; repeated delivery is safe because records retain a maximum, not an additive total. Restoring an interrupted delivery retains its original owner. Anonymous results stay local rather than being claimed after a later sign-in.

`SkyLeaderboard` owns optional networking, identity, cached value snapshots, timeout tasks and cancellation generations. `GameCenterClient` is its narrow GameKit transport. No GameKit, UI or networking import enters StarfallCore. Connection monitoring is passive and supports cellular as well as Wi-Fi. Authentication is initiated by Connect; subsequent launches initialize it after that opt-in, caching any required system controller until the player chooses Connect again.

`SkyRankingRecords` saves a local best and per-player pending maximum, acknowledged maximum and two cached scopes in `starfall.rankings.v1`. Submission and response acceptance both check player identity. Switching accounts, backgrounding, refreshing and switching scopes reject stale responses. Account caches never appear as another person's rankings. Pending scores from other accounts remain stored until that owner signs in again. A completion arriving after cancellation may have reached Apple; retrying a best score is idempotent when the board is configured for best/highest scores.

The core save and ranking sidecar are separate UserDefaults writes. A process death exactly between them can lose ranking eligibility for that run, conservatively, while preserving local play. This is not a transactional cloud outbox or tamper-proof record. Do not market guaranteed competitive delivery. Retained account metadata is small per account but not capped across arbitrarily many accounts on a shared device; revisit eviction if account switching becomes common.

## Apple setup required before live acceptance

1. Use an Apple Developer team and an app identifier that supports Game Center. Enable Game Center on the matching App ID and regenerate/select its provisioning profile. The committed entitlement contains only `com.apple.developer.game-center`; it adds no monetization entitlement. On October 17, Xcode successfully provisioned a Personal Team device build with this entitlement; this did not provide App Store Connect membership or a configured leaderboard. The user confirmed free Personal Team status, so enrolled-team access remains the blocker.
2. Create/select the matching app in App Store Connect and enable its Game Center integration. Create a **classic** leaderboard with ID **`com.starfall.prototype.standardSky.v1`**, integer score format, **high-to-low** sorting and **best score** submission policy. Provide the required localization and associate the leaderboard with the app version. If changing the ID, change its single owner `SkyRankingRecords.leaderboardID` and migrate/version records deliberately.
3. Install a properly signed build and test with real Game Center identities. Verify explicit sign-in, cancellation, sign-out/account switching, Friends and Global data, score submission and failure states. Check fresh offline launch, finishing offline then reconnecting, service unavailable with working internet, app termination during submission and foreground retry. Apple account/app configuration cannot be established by an unsigned simulator build.

Sources checked October 17: [Apple initialization](https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center), [authentication](https://developer.apple.com/documentation/gamekit/authenticating-a-player), [leaderboards](https://developer.apple.com/documentation/gamekit/encourage-progress-and-competition-with-leaderboards). iOS 17-compatible GameKit declarations were also checked in the installed Apple SDK. Review App Store privacy disclosures for score sharing before distribution; there is no custom collection endpoint.

## Acceptance

- [ ] Live Apple setup, signed-device authentication/cancellation and real Friends/Global results.
- [ ] Real device airplane-mode cold launch, local full round/save/restart, reconnect and eventual score confirmation for the same account.
- [ ] Actual VoiceOver result announcement, focus through scope selection, rows, connection and Done; real Reduce Motion and ordinary full animations remain equivalent in committed outcome.
- [ ] Human visual acceptance on phone/tablet and smallest supported iOS version.
- [x] Local checks: 61 core tests, 29 hosted checks and 6 native ranking checks passed. Three affected native layout checks and Release passed after the final row refinement; selected captures inspected. See the source-bound evidence for the earlier supporting gameplay matrix and remaining gaps.
