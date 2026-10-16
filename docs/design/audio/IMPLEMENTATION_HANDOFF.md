# Audio implementation handoff

Prepared 16 October 2026 from the current working tree and [game bible](../STARFALL_GAME_BIBLE.md). This is an integration proposal for the audio exploration, not a runtime change or an audio acceptance result. Only this document belongs to this technical audit, which generated, downloaded, listened to, bundled, and played no audio, and changed no source, test, project, save schema, or dependency. The wider audio workstream's separately approved audition batch is not an integration or validation result.

The bible calls for quiet wonder, tactile crystal release, and silence as a complete experience. Keep one primary authored cue per committed action. A later larger-group variation must not imply a multiplier, combo system, cascading clear, or extra reward. The rules have none of those systems.

## Selected starter — current implementation target

The user selected **all four quiet-tuck takes (06–09)** as the starting palette. Their [unchanged local originals and checksums](selected/README.md) are preserved outside the shipping resource list. The first pilot replaces system sound 1104 with these four alternate contacts, selected by a fixed feedback-only rotation. Use the same family for all group sizes, jewel kinds and terminal clears; do not advance core RNG. No separate settle, bright win phrase or music is part of this first slice. Gentle sound remains off by default. All four are selected; native timing, levels and lifecycle behavior still need validation.

Read [SONIC_WORLD.md](SONIC_WORLD.md) for the derived creative direction. The architecture and lifecycle guidance below still applies. Its fuller/win/music examples describe later extensions, not additional starter requirements. A future resolved win phrase would replace the normal contact as one integrated file; until then the selected tuck plays once and the existing result UI/VoiceOver carries the outcome. The user's selection authorizes this starter choice; it does not require another selection round or authorize further generation spending.

## Verified source boundaries

Line references below are a snapshot of the working tree, which already contains uncommitted runtime and visual work. Recheck the named symbols before integration.

| Boundary | Observed behavior | Audio implication |
| --- | --- | --- |
| `Sources/StarfallCore/Game.swift:23–25,37,86–104` | `Turn` has `cleared` and `reshuffled`; the game commits moves, score, refill, and bounded three-cell recovery synchronously. Outcome checks the goal before zero moves. | Consume the committed turn/outcome. Do not add audio imports, timing, asset IDs, random selection, or playback state to core. `reshuffled` means local recovery, not a full-board shuffle. |
| `App/GameFeedback.swift:6–28` | Injected `@MainActor GameFeedbackProviding` exposes `cleared` and `announce`. `cleared` plays system ID `1104` only when `soundEnabled`; it then handles haptics. VoiceOver announcements use a separate method. | Reuse this boundary. Replace the system cue with a local asset through a small player owned by feedback. Do not play both. No sound character, silent-switch, latency, or mixing behavior for ID `1104` is established by this audit. |
| `App/GameStore.swift:19–26,43–45` | Leaving play or opening Settings settles presentation. `soundEnabled` and `calmEffects` use local `AppStorage`; both default to false. | Preserve the existing sound key and off default. Muting must immediately stop owned audio, not merely suppress the next cue. |
| `App/GameStore.swift:123–144` | Taps require play, no sheet, no busy turn, and a playing outcome. Invalid taps announce “No move used” and nudge. A valid tap receives a UUID, saves its committed result, then calls feedback once before animation. Completion checks the UUID, clears busy, and announces once. | The valid commit is the authoritative audio trigger. Never derive cues from SwiftUI redraws, score observers, `render`, or individual SpriteKit pieces. Keep invalid and rejected taps silent in the first pass. |
| `App/GameStore.swift:101–121` | Start renders a saved/current board. Settlement invalidates the turn and renders its committed state. Restart cancels presentation and starts a new round. | Loading a result, returning to play, resizing, and restarting must not replay the previous action or terminal phrase. Add cancellation for deferred audio work without changing saves or unlock timing. |
| `App/JewelScene.swift:73–94,259–288,327–340` | Motion is bypassed for Calm effects, system Reduce Motion, VoiceOver, or no attached view. Otherwise a 200 ms clear leads to the arrival adapter; scene and store have separate stale-callback guards. Resize/detach settle through the store. | Completion can happen synchronously. Audio must work without an animation clock. Do not schedule a sound for every visual arrival or make audio completion unlock input. |
| `App/JewelScene.swift:375–414` | Touch-down previews a legal group; moving away, cancellation, or extra touches cancel. A tap commits only on touch end in the original cell. | Preview is not a clear. The first pass should keep preview silent so canceled touches cannot sound like committed actions. |
| `App/StarfallArrivalEffects.swift:5–9,44–61` | The adapter owns a 280 ms refill phase after the clear, for a 480 ms presentation target, with an immediate settled alternative. | This is a timing target, not measured audio synchronization. A settling accent, if approved, is at most one accent per turn through guarded completion. |
| `App/StarfallApp.swift:37–51,73–77` | Reduce Motion and Calm changes update the presenter. Every nonactive `scenePhase` settles presentation. Settings has “Gentle sound,” “Calm effects,” and Done. | Add explicit foreground/audio policy handling here or through the store. Current settlement does not stop or pause a dedicated audio player because none exists. |
| `Starfall.xcodeproj/project.pbxproj`, `Package.swift` | The app has explicit source/resource build references. SwiftPM contains only core and its tests. No authored audio resources or custom audio session setup were found in the inspected app/project. | Adding files to a folder alone is insufficient. Accepted audio belongs in the app target's resources, never the core package. |

The working tree is ahead of the bible's status section: touch-down preview and shooting-star arrival integration are present in source. This is source evidence only; it does not approve their feel or establish a device result. Do not revert or overwrite that work to match an older handoff.

## Small local architecture

Use Apple's bundled-audio playback APIs in the app layer. An `AVAudioPlayer` implementation is a reasonable first experiment for a few short, pre-authored cues and one optional loop. It is a recommendation to measure, not a latency guarantee. Start with a bounded player pool: at most two effect voices and one music voice; prioritize the newest committed cue and suppress excess tails rather than allocate per shard. If this proves insufficient on device, profile the failure before introducing an audio engine.

Keep responsibility in three places:

1. **Store:** emits the already committed action, its existing turn ID, final outcome, and only the presentation metadata actually needed. Keep the current immediate save and input lock. If timbre needs the cleared kind, read it from `old` before the board mutates visually; all cells in a valid group share a kind. Choose a stable cell rather than depending on `Set` iteration order.
2. **Feedback:** receives one semantic request per valid turn and combines it with the existing haptic/announcement policy. Use the committed outcome directly: win takes precedence and selects one composite phrase that includes its initial crystal release; loss uses the normal group-clear cue followed by silence. Do not stack clear, final-move warning, loss, and win sounds. If the provisional rapid-input coalescing in [SOUND_EFFECTS.md](SOUND_EFFECTS.md) is adopted, distinguish receiving a valid event from playing it: ordinary clears may be dropped within that audition window, but both terminal outcomes bypass it. Never turn a dropped cue into delayed playback or suppress the final loss clear just because its asset is an ordinary-clear file.
3. **Local player:** loads only a fixed bundled manifest, owns bounded players and session notifications, and gates playback against the current preferences and lifecycle. Missing or unreadable assets fail silently to playable game state. No retries that block play and no fallback network fetches.

Keep provider changes small. Immediate action playback needs no SpriteKit sound actions. Add an explicit lifecycle/cancellation operation only when the player has something to cancel. Deferred accents, fades, and loop starts must capture a generation/token and recheck current permission to play when they execute. A stale task must not restart sound after mute, Settings, restart, backgrounding, or a newer round.

Do not add a second timer that assumes the scene will finish at exactly 480 ms. If listening proves a settling accent useful, attach it to the existing guarded completion and suppress it on canceled or immediate-motion paths, on terminal actions, and on free-recovery turns. It must never add a delay. Skipping this accent entirely is the simplest first integration.

Sound variation must not advance `Game`'s seeded generator, alter the save payload, depend on wall-clock timing for game outcomes, or introduce a combo counter. A fixed variant rotation in the audio provider is sufficient for auditioning. Do not build a five-kinds × group-sizes × every-transition asset matrix before hearing whether those differences matter.

ElevenLabs is an authoring tool outside the game. Production playback uses accepted local files; no plugin credentials, generation calls, remote URLs, SDKs, tracking, purchases, entitlements, or background-audio capability belong in the target. Keep an asset manifest with source/generation provenance, version, intended event, duration, channels, sample rate, file size, and loop boundaries. Preserve source masters outside the shipping resource list. Confirm rights and the repository's no-paid-assets constraint before admitting a generated candidate as a production asset.

## Preferences and audibility policy — recommended

Retain `soundEnabled = false` as the master “Gentle sound” control. In an effects-only pass, no additional setting is needed. If background music is selected later, add a separately persisted “Music” preference defaulting to false, gated by the master. An existing user who enabled the old single system cue should not unexpectedly acquire continuous music after an update. Turning music off stops music; turning Gentle sound off stops both. Neither operation suppresses VoiceOver announcements.

Calm effects and Reduce Motion currently suppress motion and haptics, but do **not** mute the optional cue. Preserve that distinction. Do not infer a user's audio preference from a motion preference. Avoid adding louder or more urgent audio when moves run low; no ticking, countdown pulse, rapid-tap reward, or timer-dependent musical escalation.

| Situation | Recommended effect behavior | Recommended music behavior |
| --- | --- | --- |
| Fresh install / all sound off | No playback or eager audio-session activation | Off |
| Valid normal clear | One warm crystal release | Continue quietly if independently enabled |
| Invalid tap / canceled preview / busy or terminal-board tap | Silent; existing accessible explanation remains | Unchanged |
| Win on any move, including the last | One resolved phrase selected from the committed `.won` result | Briefly make room for the phrase; no extra celebration state |
| Loss | Normal final-clear cue followed by silence; no separate loss sting | Stop or settle gently; decide through listening |
| Free recovery | No extra reward or shuffle sound | Unchanged |
| Restart | Cancel old tails and pending terminal cues; no automatic reward cue | Keep a continuous bed or restart softly only if chosen in audition |
| Menu / Settings / app becomes inactive | Cancel pending game cues; no delayed playback from the prior board | Pause; resume only from an eligible current state |
| Settings dismissed / app active again | Never replay missed effects | Re-evaluate preferences, interruptions, route hold, and other audio; do not infer eligibility from dismissal alone |
| Reduce Motion / Calm enabled during a turn | Cancel optional delayed turn accents; keep silent mode and sound preference authoritative | Do not mute solely because motion changed |
| View resized / scene detached | Invalidate pending turn accents; do not replay commit | A resize alone should not restart a soundtrack |

`settlePresentation()` serves several reasons, including layout, settings, backgrounding, and accessibility changes. Do not blindly treat every call as a soundtrack stop/start cycle. Keep cancellation of stale turn accents distinct from whether the app is eligible to play continuous audio.

## Platform policy and remaining listening decisions

**Verified Apple semantics:** `.ambient` is intended for optional app audio, mixes with other apps, and is silenced by the Silent switch and screen lock. This matches Starfall's optional sound intent. Use this as the candidate session category; device checks are still required. [Apple: ambient](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/ambient).

Avoid eager preparation while sound is off. Apple documents that `AVAudioPlayer.prepareToPlay()` acquires playback resources and activates the audio session, and that stopping or finishing undoes that preparation. Cache bounded assets, then prepare when playback is eligible; verify the first cue and repeated-cue latency. [Apple: prepareToPlay](https://developer.apple.com/documentation/avfaudio/avaudioplayer/preparetoplay%28%29).

For another app's primary audio, propose leaving optional quiet effects available while suppressing Starfall's music. Apple's `secondaryAudioShouldBeSilencedHint` specifically supports this game soundtrack/effects distinction; it indicates another **nonmixable** session, not every possible sound from another app. Its change notification reaches foreground listeners with an active session, so also recheck the value when becoming eligible to play. These APIs do not prove good VoiceOver mixing. [Apple: secondary audio hint](https://developer.apple.com/documentation/avfaudio/avaudiosession/secondaryaudioshouldbesilencedhint), [Apple: hint notifications](https://developer.apple.com/documentation/avfaudio/avaudiosession/silencesecondaryaudiohintnotification).

Observe interruptions and route changes. On interruption begin, stop transient cues and pause music; on end, discard missed cues and re-evaluate present eligibility. For the iOS 17 baseline, use APIs supported by that target and verify SDK availability; current Apple documentation also exposes newer session APIs. Do not copy a newly documented symbol without its availability guard. Apple documents the interruption notification flow and resumption options. [Apple: handling interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions).

When headphones disconnect, propose pausing music and canceling outstanding effect tails, with no automatic switch to a public-speaker soundtrack. Keep a route hold until an explicit sound/music enable action or a newly connected private route; test the user experience before finalizing. Apple recommends pausing playback when headphones are disconnected. Route notification itself is not evidence that an `AVAudioPlayer` wrapper implements this policy correctly. [Apple: route changes](https://developer.apple.com/documentation/avfaudio/responding-to-audio-route-changes).

For VoiceOver, default the experiment to music suppressed while VoiceOver runs and short effects below speech. This is a Starfall recommendation, not an asserted platform requirement. Keep result/group information in accessible text and announcements, and never block a VoiceOver action while waiting for audio. In the current immediate-motion path the announcement can follow the cue immediately; hearing that combination is required. If intelligibility suffers, suppress effects while VoiceOver is active rather than postponing the result announcement. A sound toggle assertion or accessible-board launch argument does not test real spoken VoiceOver.

Open audition decisions: whether a loop adds calm or repetition fatigue; whether a settling accent adds information; whether the shared material family needs further variation; and whether VoiceOver needs all authored audio suppressed. The first audition has no separate loss sting or five-kind sample bank. Do not add more preferences solely to postpone these decisions.

## Integration checks to perform later

No tests, simulator build, simulator run, or device listening were executed for this document-only audit. Existing test source is evidence of intended coverage, not a fresh pass result. `AppTests/GameStoreInterruptionTests.swift` already covers one feedback invocation per valid turn, silent invalid turns at the clear-feedback boundary, canceled/repeated announcements, busy input, settings/menu blocking, and stale completion safety.

When runtime integration is requested, add focused tests with an injected recording player/session boundary:

- Exactly one semantic request per successful turn and at most one primary playback; zero requests for invalid, busy, canceled-preview, restored, or terminal-board taps. Repeated completion cannot duplicate cues. If rapid ordinary clears are coalesced, test dropped playback separately from event receipt and verify both terminal outcomes bypass suppression.
- Final-move win selects win and never loss; free recovery does not add a move, score, or second action cue.
- Sound off defaults and saved preference behavior; adding music does not silently enable it for existing sound-on users. Mute cancels active/pending audio immediately and later callbacks stay silent.
- Restart, menu/settings, inactivity, detached scene, and interrupted/repeated callbacks cannot emit an old result or unlock a newer turn. Synchronous Calm/Reduce Motion/VoiceOver completion does not overlap an optional settling accent.
- Bounded voice allocation, optional-asset failure, interruption, route hold, and secondary-audio policy do not change the game state or block input. Use policy fakes rather than claiming a unit test proves real audio routing.

Run `swift test`, an iOS simulator build with the shared `Starfall` scheme, and the hosted app/UI tests appropriate to changed files. Inspect the final built app resource list and confirm no network/SDK, entitlement, background mode, ad/IAP, or analytics additions. Then collect native evidence:

| Native scenario | What must actually be observed |
| --- | --- |
| Normal and repeated play | First-cue latency, alignment with touch-end release, no brittle/high-volume surprises, no clipping or fatigue; group size changes texture without implying a score multiplier |
| Rapid taps, drag cancellation, multiple touches | At most the legal committed actions sound; no cue pileup or lingering voices |
| Win/loss and final-move win | One win phrase or normal final-loss clear, immediate visible result, no loss sound on a win, no replay after Continue/relaunch |
| Restart at clear/refill/phrase tail | Old sounds and scheduled work canceled; new board unaffected |
| Settings presentation, both dismissal paths, sound toggles | Immediate mute, no board cues under the sheet, no missed cue on return; persisted state matches labels |
| Background/lock/resume during every phase | Silence when inactive, stable saved round, no old cues or unintended soundtrack restart |
| Real VoiceOver and motion settings | Spoken labels/results remain intelligible, navigation works, full information remains when sound or motion is off; test live setting changes |
| Silent mode and system volume | Optional audio follows intended device policy at low/normal volume; no workaround for system mute |
| Another app's music/podcast, interruptions, wired/Bluetooth routes | Other audio is not displaced; soundtrack suppression, call/Siri interruption, disconnect, and reconnect behave as chosen |
| Repeated rounds on a supported physical iPhone | Audio memory, player counts, frame pacing, battery impact, speaker/headphone balance, and loop seam remain acceptable |

Record the device/simulator, OS, output route, sound/music preferences, accessibility state, artifact version, and observed result. Simulator output does not establish physical silent-switch, headphone-disconnect, haptic, energy, or speaker quality. Audio cannot be accepted from waveform metadata or screenshots alone.
