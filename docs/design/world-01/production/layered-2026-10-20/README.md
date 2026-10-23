# Modular world-map art

**Status: Original modular composition adopted for development; the current catalogue has seven islands through Sunwheel Mill.** [Native input, inspected appearance, Release membership and acceptance limits](../../../../evidence/ui-adversarial-2026-10-20/IMPLEMENTATION.md) identify the verified sources.

This is the modular replacement for the rejected [whole-map prototype](../interactive-2026-10-20/README.md). The approved concept supplies materials and landmark identity. It does not supply runtime screen geometry. The [production workflow](../../../UI_PRODUCTION.md) requires a real native slice before expanding the family.

## Ownership and acceptance

Core owns access and completed repairs. `WorldJourneyStore` owns persistence; `SkyFlowState` owns navigation. An app presentation snapshot translates those facts into independent access, repair and selection values. The map content catalogue owns assets and attachment metadata. The renderer composes that content, reports native selection intents and owns decorative lifetime. Assets have no authority over game rules, input, saves or unlocks.

The same production renderer serves the normal route and seven isolated Debug review states. The six-island acceptance and pixel budget below retain their original October 20 scope; [Sunwheel’s integration](../../../../evidence/sunwheel-mill-2026-10-20/MAP_INTEGRATION.md) and [Ribbon’s current revision](../cohesion-2026-10-23/README.md) identify the later seven-island checks. Original acceptance requires:

- One recognizable island and its native marker across compact phone and tablet, with real taps, Entry/Back and readable labels.
- Different neighboring repair states without revealing or changing other islands. Selecting locked art changes only selection feedback.
- Visible, stationary targets at least 44 points, clear selected state without color alone, and a reachable selected-place action. Compact layouts scroll instead of shrinking terrain or text to fit every island.
- Separate crop-safe sky and alpha clouds; bounded ambient motion stops when quiet, inactive or covered. No whole-screen timeline invalidation.
- All six ready identities, default/large text and both tablet orientations inspected before adoption. Largest text uses equivalent native Places.

## Asset contract

The constraints below are checked against each export; measured geometry and hashes belong in `generation.json`. A failed export changes the asset or its explicit metadata, never silently changes progression or touch targets.

| Layer | Contract |
| --- | --- |
| Sky | One opaque crop-safe painting without islands, text, markers or focal cloud shapes. Aspect fill may crop this decorative layer. |
| Cloud | One transparent reusable mist cluster, no sky or terrain. Three bounded instances at most; never intercept input. |
| Island | Six ready identities × dormant/restored. Actual exports use square 1254-pixel RGBA canvases, a consistent elevated orthographic camera and complete silhouettes. Preserve aspect; never stretch or crop terrain. |
| Registration | Top-left normalized source coordinates, measured dimensions and union of both states' alpha≥128 bodies. Record landmark-specific marker anchors and route ports. Retain source transparency plus 8% logical canvas clearance. Exports may contain isolated alpha1/255 fringe at a corner; native inspection must find no visible matte. |
| State | Repair chooses one asset from committed completion only. Locked/ready, selected/focused and pressed are independent native treatments. No fabricated partial-completion art or cross-island masks. |
| Native layers | Route curves from ports; teardrop shape, shared Observatory glyph, text and controls. Native controls retain measured layout and accessibility. No baked names, UI or outgoing bridge fragments. |
| Size | Canvas floor220 points, phone maximum300, two-column tablet maximum320 and three-column maximum300. Native nameplates sit below terrain and wrap at their measured size. The complete island is one stationary native button; the visible pin is32×42 points. Phone scrolls; tablet rows share the available height, retaining scrolling when labels or expanded content need it. |
| Original budget | Six island textures plus one sky and one shared cloud image used by the scene. The fourteen exported images total 88,062,288 bytes (83.98 MiB) as RGBA8 source pixels. `generation.json` records the estimate; it excludes framework caches, intermediate and GPU copies and is not measured peak residency. No unbounded custom cache or frame-time decoding. Profile device memory before expanding the catalogue substantially. |

Original source PNGs and exact built-in image-generation prompts remain here. Runtime assets were byte-identical copies at that delivery. [Ribbon’s October 23 revision](../cohesion-2026-10-23/README.md) now owns its damaged runtime PNG; `generation.json` records that override while retaining the original entry unchanged. Other original exports keep their recorded source scope. Generation itself does not verify alpha, registration, memory use or appearance at native size.

## First expansion: Frostfruit Orchard

Frostfruit follows the sixth playable location introduced on main at `d94903b`. Its official completed level painting supplies the snowy opal tree, hanging glass-bell fruit, collecting trays and bench; the Lantern and Ribbon map cutouts supply the existing map camera and materials. The restored central fruit opens visibly, while the registered dormant edit keeps the same terrain and crown with sealed opaque fruit and unlit lamps. Winter snow remains present in both states.

Both exports are 1254×1254 RGBA with transparent corners and actual zero-alpha pixels. Their alpha≥128 union is `(26,31)`–`(1247,1219)`. The pin uses the front path at normalized `(0.50,0.71)`, below the central fruit; the catalogue records four optical route ports on the shared terrain. All five attachment points have alpha≥250 in both source states. Prompts, reference roles, hashes and source measurements are in `generation.json`; native fit, input and state review pass the selected six-island checks linked above.
