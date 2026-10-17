# Cosmic theater — composition studies

Hypothesis: distant cosmic scale, layered painted cloud forms and a planet/event-horizon landmark create wonder and a sense that stars arrive from a larger universe. Earlier palette-only options did not reach this direction.

References: Paper Mario's storybook construction and Fountain of Dreams' luminous night atmosphere. Original compositions; no imported Nintendo imagery. Three studies: Planetrise, Dream Nebula, Eventide. Six proposed production depth planes: inky infinity, far stars, nebula veils, sculpted gas, atmospheric haze, foreground cloud framing. Concepts depict those planes in a single painting. They are not separated parallax assets yet.

Bounded scope: generate art, assess against native populated stars, export an isolated scene-composition lab with a nearly absent board panel. No production route/default/assets changed. No rule, save, geometry, clock, progression or SDK changes. Existing cosmetic options remain the production baseline.

Acceptance: landmark/scale recognizably differs across vantage points; characters and dark stars readable without opaque panel; native menu dismissal retains committed board summary; art aspect/cropping inspected; decorative layers do not receive touches or accessibility focus. Static studies cannot prove motion, enjoyment, frame pacing or real VoiceOver. Future animated planes must freeze for Reduce Motion/Calm effects and suspension, remain bounded and never consume game RNG.

Decision point: compare these three compositions with populated native screenshots. Pick a visual direction before producing separated cloud/nebula layers or adopting runtime art. Specifically assess whether the painterly treatment needs stronger sculpted paper edges and simpler shapes to match the cast.

Historical reproduction used `prepare-cosmic-lab.py` on the source described below. That exporter was retired when Observatory entered production; these flattened composition studies remain references, not a supported parallel runtime. The original export recorded HEAD and dirty status, not a clean published revision.

Generated with the built-in image generator. Exact prompts in `prompts.json`; PNGs are original generated study assets. Native result/evidence recorded after checks.

## Native result — 2026-10-17

Isolated export: `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/starfall-cosmic-lab-98mmv9w0`; source manifest `COSMIC-LAB-SOURCE.txt` records HEAD and working-tree differences. Xcode 27.1, iPhone 17e / iOS 27.0, dedicated simulator `CDF20AC9-729B-4AB2-9B00-2F50E1A3766B`. Debug native UI build/test passed; three environment selections and menu dismissal retained the same paused six-shower board summary. Native attachments exported and visually inspected for all three. Release arm64 simulator build passed. Core `swift test`: 61 tests, zero failures. Hygiene and diff whitespace checks passed. No shared production app source changed in this tranche; lab overrides exist only in the export.

Commands: `xcodebuild -project <export>/Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=CDF20AC9-729B-4AB2-9B00-2F50E1A3766B' -derivedDataPath /tmp/StarfallCosmicBuild ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -only-testing:StarfallUITests/FallingSkyInteractionTests/testEnvironmentSelectionPreservesPausedBoard test`; Release uses `-configuration Release -sdk iphonesimulator -derivedDataPath /tmp/StarfallCosmicRelease ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build`. Raw logs/screenshots in ignored `artifacts/cosmic-01/` and `/tmp/starfall-cosmic-*`; xcresult `/tmp/StarfallCosmicBuild/Logs/Test/Test-Starfall-2026.10.17_10-37-39--0400.xcresult`.

Visual findings: Eventide has the strongest dark negative space around the current stars; Dream Nebula has the most tactile framing. Planetrise's bright lower clouds compete with the bottom row. Menu icon sits over a bright landmark in some views; controls need a localized contrast treatment. More distant stars need simplifying so decorative stars never look playable. Dense-board, iPad/landscape cropping, actual VoiceOver, Increased Contrast/Reduce Transparency, background/resume, rapid taps, terminal/restart and physical device remain unverified for this lab. Stills do not verify motion or frame pacing. Hosted suite was not rerun because no store/renderer implementation changed; its previous source-bound failures remain open in engineering.

Decision: retain as isolated composition studies, favor Dream Nebula/Eventide for the next craft pass. Do not adopt the flattened art as a completed layered renderer. Next work is to simplify fine stars, strengthen paper silhouettes, darken the bottom cloud shelf, and produce separately authored far/mid/near planes for one selected composition. Profile only after a reproducible native motion scenario exists. Adopt/remove decision after that comparison, with input, interruption, accessibility and full-motion evidence.
