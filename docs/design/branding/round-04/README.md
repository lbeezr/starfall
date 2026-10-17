# Starlight Garden — full portrait cover

October 17, 2026. User selected round three's middle Starlight Spring and requested garden details from the left, a full-size cover, wordmark and Play button.

Acceptance for this design: one 2:3 portrait cover; central gathering spring and arriving aqua hero; flowered terraces and soft cloud framing; separate editable SVG wordmark; readable primary Play action with quiet surrounding space. This is a reviewable cover artifact, not native game integration.

`sanctuary-background.png` is original AI-generated illustration, using the prior round as reference. It is deliberately text-free so title and controls stay independently editable. `cover.html` composes that art with the existing round-two pearl SVG wordmark and a semantic HTML button. `cover-full.png` is the full 1024 × 1536 browser export; `cover-phone.png` is a 390 × 844 browser viewport proof with the full cover letterboxed. `index.html` offers the preview and individual assets. The generated raster is not edited after generation; the cover is composed in HTML/CSS and exported from the browser.

The button has native keyboard focus, a 44 CSS-pixel minimum height, and an accessible description explaining that gameplay is not connected. It does not navigate or pretend to launch the game. No added loading delay, progression, game rules, startup code, icon, app resource or dependency. Production should use native controls and the existing theme and route contracts. AI artwork may vary secondary cast details; normalize against StarCast before any production adoption.

Decision point: review this full composition before exporting production layers or implementing native title/controls. If selected, follow with native phone-size layout, safe-area/Dynamic Type, actual VoiceOver, interruption and motion checks. Those checks, animation and physical-device evidence are not supplied by static browser exports.

Verification: full-size export visually inspected; browser images load. At 390 × 844, Play is about 203 × 44 CSS pixels, can receive keyboard focus, and there is no horizontal overflow. Phone viewport proof visually inspected separately. Rendering used installed Google Chrome through bundled Playwright; no app/browser packages added. Hygiene and whitespace checks passed. Source context is the existing dirty working tree; all changes from this task stay in `round-04/`. These checks are browser design evidence, not native app or actual VoiceOver acceptance.
