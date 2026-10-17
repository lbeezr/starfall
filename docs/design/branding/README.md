# Starfall branding exploration 01

Later retained studies: [Soft Bloom lettering](round-02/README.md), [celestial sanctuary scenes](round-03/README.md), [full Starlight Garden cover](round-04/README.md), [first icon options](icons-01/README.md), and [falling Spark icons](icons-02/README.md). These are design artifacts outside the app target; saving them does not adopt a cover, navigation flow or replacement icon.

October 17, 2026. Design studies against repository HEAD `b9eea1a` and the current working tree. Open [the comparison sheet](index.html) or [the rendered board](review-board.png).

## Brief and review criteria

Explore an original editable wordmark and a coherent cover / launch / optional loading sequence. Compare the approved glass icon with cast-led candidates. The marks must read “Starfall,” work in one color, have no font dependency, and fit the existing midnight / plum / moonlight palette. Cover composition should give one clear primary action and room for the cast. Deliver outside the app target for comparison; adoption is a separate design decision.

## Recommendation

Develop **Soft Landing + Spark**. Rounded lowercase lettering connects to the current expressive cast. Tall ascenders keep the silhouette distinctive; the last two stems descend slightly to suggest falling. The glint is separate from the lettering so recognition does not depend on decoding a substituted glyph. **Night Observatory** is an original alternate uppercase construction: calmer and more architectural, but weaker at small sizes and less playful.

The recommended wordmark is entirely original SVG path geometry, including rounded stroked centerlines; it is not live text or a converted third-party font. If production tooling needs filled contours, expand strokes at export while preserving this editable source. Keep moonlight on midnight or dark ink on moonlight. Proposed minimum display width is 140 points with 12 points of clear space; confirm at native display scale before adoption. At smaller gameplay-header sizes, retain native readable text until a dedicated compact treatment is reviewed. Give an adopted mark the accessible name “Starfall”; decorative glints are hidden from accessibility. Other reading text stays native and responds to Dynamic Type.

| File | Purpose |
| --- | --- |
| `wordmark.svg` | Transparent moonlight Soft Landing signature |
| `wordmark-ink.svg` | Same path geometry in midnight ink |
| `wordmark-orbit.svg` | Transparent Night Observatory alternate |
| `cover-soft-landing.svg` | 390 × 844 cover study; tagline is exploratory |
| `launch-quiet.svg` | Static launch composition |
| `loading-starlight.svg` | Still frame of an optional real-work state |
| `icon-spark.svg` | 1024 × 1024 opaque aqua cast candidate |
| `icon-sunny.svg` | 1024 × 1024 opaque amber cast candidate |

`generate.py` owns the shared study lettering, palette and character geometry. Regenerate with `python3 docs/design/branding/generate.py`. No additional package is required. These are design-authoring values, not a second runtime theme. Runtime colors remain owned by `StarfallTheme`; runtime characters remain owned by `StarCast`. The SVG cast interpretations are simplified studies and must not become an independently maintained game renderer. The HTML references the existing icon source directly for comparison. Screen labels and descriptive copy use system fonts; only the wordmarks are font-independent.

## Arrival and motion intent

Cover: quiet sky, one hero, two supporting stars, Play and secondary Settings. Production must preserve existing resume/challenge behavior; the cover is a composition study rather than a new navigation contract. No progression or new gameplay is proposed.

Launch: static composition only. On adoption, match its geometry and background to the first actual app frame. Loading: show only if measured startup work needs it; enter usable play immediately when ready. No artificial minimum duration or pretend percentage. The current frame shows “Gathering starlight” with three dots, not a progress measurement.

Possible adoption motion: a single restrained hero settle and a short crossfade from launch to app content; no looping shower on the cover. Reduce Motion and VoiceOver use stable artwork and the same available controls. Any startup task must follow existing main-actor ownership, cancellation and generation contracts, including background/resume and replacement. Animation completions must never decide readiness or game state. These motion ideas have **not** been implemented or animated here.

## Icon decision

Keep the approved glass icon until native comparison supports replacement. Spark best bridges the current aqua identity to the cast; Sunny is warmer but has a more familiar five-point silhouette. The 60/40/24-pixel browser proofs suggest the silhouette can carry recognition when the face is too small to matter. These are not Home Screen results. Source candidates have opaque full-bleed square backgrounds; rounded masks appear only in the review HTML. Adoption requires native PNG export, correct catalog membership and actual Home Screen inspection, including small size, light/dark backgrounds and system treatments. No alternate icon switching or assets were added to the app.

## Verification and decision point

- All eight SVG documents parsed as XML; marks contain no live text, scripts or linked imagery.
- Local comparison sheet rendered with Playwright using installed Google Chrome, 1440-pixel viewport. All 12 image instances loaded; no page JavaScript errors. `review-board.png` was visually inspected for lettering, clipping, screen spacing, icon comparisons and small-size previews.
- `python3 scripts/ci-hygiene.py`: passed. `git diff --check`: passed.
- App/core/save behavior: unchanged by this work. Swift tests, native builds, gameplay, interruption, actual VoiceOver, Dynamic Type, native icon rendering, animation and physical-device acceptance were not run for these standalone design files.
- Other working-tree edits were present, and additional scene/view/theme/UI-test edits appeared during the session. This work changes only `docs/design/branding/`; the preview is not acceptance evidence for those app edits or a published commit.

Review these studies before app integration. Choose a wordmark and icon direction, then adopt the selected assets with native layout/motion/accessibility checks; archive rejected variants as design history. No pilot flags, production routes or temporary app resources need removal. Current open decision: whether the softer lettering and cast-led icon are the desired brand personality.
