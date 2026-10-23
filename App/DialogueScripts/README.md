# Write Starfall copy

The regular Falling Sky app uses one bundled English catalogue: [observatory-dialogue.json](observatory-dialogue.json). `scripts` owns character lines, speakers, priorities and reading duration. `copy` owns menu labels, help, results, pacing, touch feedback, save-recovery notices and accessibility wording. Wording edits stay here; Swift supplies committed facts and selects events. This is local content shipped with the app, not a remote CMS, runtime AI or a translation system.

[SkyCopy](../SkyCopy.swift) provides typed interface keys. The library checks that the JSON keys exactly match that inventory. Dialogue and interface copy share strict placeholder rendering: missing, extra and brace-containing values fail validation. The editor [schema](dialogue.schema.json) and hosted `SkyDialogueTests` check content, packaging, all templates and event behavior. There is no silent fallback to an English sentence hidden in a view.

**Boundary:** Debug studio labels, reset-only fixture descriptions and the original Debug orthogonal puzzle retain developer/test text in Swift. Numeric score displays and punctuation used for joins are formatting, not alternate prose stores. Do not put new regular-game instructions in a view or store.

## Change interface wording

Edit a value under `copy`, preserving its key and `{tokens}`. For example, `action.new` is shared by the welcome, menu and result screens. Full sentence templates allow values to move without rebuilding a sentence in Swift. Separate one/many templates handle counted phrases. Counts come from Core, including the retained Dusk rule's three/five feeds and orbit duration.

The catalogue admits at most 1,024 copy entries of at most 1,600 characters each; the editor schema and runtime share that bounded capacity. `SkyDialogueCatalogBoundsTests` checks capacity and rejection, and `SkyDialogueTests` checks the actual shipped inventory. A new interface message needs a `SkyCopy.Key` case and matching JSON entry; an existing message needs only a wording edit. Pass through `SkyCopy.text(.resultBlocked, values: ["column": String(column + 1)])`. Add focused tests when introducing a new condition or changing which event speaks. The current format is English-only; adding other languages needs an explicit localization design, not another dictionary pasted into a view.

## Keep the cast recognizable

| Speaker | Voice and production role | Example / condition |
| --- | --- | --- |
| Sunny | Warm, practical guide; starts the game and celebrates First Light | “Here they come! Clear matching stars to make space.” — showers started |
| Spark | Curious, excitable observer; growth, Opals and traced clears | “You connected 5!” — a committed five-star trace |
| Pip | Brief, dry, practical; ordinary clears, shapes and arranging | “That made room.” — a committed clear |
| Twinkle | Gentle reassurance; pause, restore and full-sky endings | “We can stay here a while.” — automatic showers paused |
| Nova | Unhurried, precise; forecasts and compatibility gravity guidance | “Showers are closer together now.” — actual faster phase |
| Dusk | Mischievous appetite; explains its effects and teases after a concrete outcome | “Left those for me? Delicious.” — actually consumed stars |

Tease the situation, not the player's ability. Dusk's zero-starlight reaction requires a committed drained clear; invalid taps receive actionable help. Never guess that a move was strategically bad. No taunt after restoration, from a stale callback, or because the player was slow. Advice must match current rules; no “take your time” during automatic play. Celebration never changes points or awards a multiplier.

Keep one concise reaction per chosen event. Automatic showers still speak only designated transitions/outcomes; there is no chatter queue, random variant engine or gameplay RNG consumption. Explicit actions retain readable/spoken feedback. A joined forecast keeps the result's speaker; a standalone forecast uses Nova. Review the complete joined text, not only separate templates.

## Change dialogue wording

Edit [observatory-dialogue.json](observatory-dialogue.json), then open **Sky menu → Development → Dialogue studio** in a Debug build. Choose your script, fill any token fields, and press **Play script**. The preview uses the real bubble and portraits at the device's text size; it cannot change your round. Release builds include the shared renderer and content, without the studio route.

The local [editor schema](dialogue.schema.json) supplies field and speaker choices in JSON-aware editors. It is authoring help, not a network dependency; runtime validation remains authoritative.

The [runtime types](../SkyDialogue.swift) validate this format. The [library](../SkyDialogueLibrary.swift) loads this one bundled file once; existing messages, welcome, entry and endings use it. A change to text or speaker needs no view/store edit. New scripts in this file need no new Xcode resource membership.

## Add a script

Add an object to `scripts` and keep `schemaVersion` at `1`:

```json
{
  "id": "cloudsea.arrival",
  "lines": [
    {
      "id": "cloudsea.arrival.hello",
      "speaker": "twinkle",
      "text": "A softer sky. Let's see what we can discover.",
      "priority": "help"
    },
    {
      "id": "cloudsea.arrival.look",
      "speaker": "spark",
      "text": "Look at those clouds!",
      "priority": "help"
    }
  ]
}
```

**Authoring example only:** this does not add Cloudsea, a map, progression or a new gameplay route. Stable script IDs name the scenario; stable line IDs name the event. Do not rename existing IDs for wording edits. IDs must be unique, including line IDs across scripts.

| Field | Values / behavior |
| --- | --- |
| `speaker` | `sunny`, `spark`, `pip`, `twinkle`, `nova`, `dusk`; identity changes portrait, visible name and accessible attribution together. |
| `text` | 1–400 characters. Keep active-play messages short; long instructions belong in help or a player-paced script. Native text wraps and scales. |
| `priority` | `routine`, `help`, `warning`, `outcome`, in ascending order. Lower priority cannot replace visible higher-priority information; repeated identical events do not restart it. |
| `seconds` | Optional number from 4 through 30. Omit for player-paced reading. A multi-line script waits for Continue; a final timed line may expire. VoiceOver keeps messages visible with a Close action. |
| `{token}` | Explicit caller-supplied text, such as `{score}`. Missing and unused values are authoring errors, as are unresolved braces. Values cannot contain braces. |

Keep counts and gameplay facts in values supplied from committed state; do not put random choices, scoring, timers, save data or branching conditions into JSON. Avoid claims about a storm or changed pace unless that rule actually applies in the current game. Player-requested rule help is player-paced and reopenable; routine reactions may expire.

## Trigger it from a scenario or map

After the scenario's own committed event and lifecycle checks, the main-actor controller can call:

```swift
store.say(SkyDialogueLibrary.script("cloudsea.arrival"))
```

`store.say` returns whether presentation accepted the script. It rejects events while the store is suspended or the sky has ended. The store owns explicit speech; the session owns which line is visible. Future async map loaders must reject stale results at their own owner before calling this synchronous hook. Dialogue never starts/pauses a shower, changes rules, writes saves or advances a map.

`SkyDialogueSession` holds one current message/short script. There is no automatic event queue. Continue changes speaker/text atomically; Close retains information for the portrait's Read message button. Restart clears the session. Settings/background cancel the view's expiry task and keep committed gameplay intact; returning gives retained information a fresh reading interval. Script dismissal retains its place for reopening, without replaying already-read lines.

For a different host without a game store, own `SkyDialogueSession` in `@State`, call `play(script)`, and pass it to `SkyDialogueOverlay` with narrow lifecycle/next callbacks. That host owns any accessibility announcement and cancellation of its own event producers. Do not give the bubble an entire map or mutable game store.

## Update portraits or styling

The six `Dialogue<Name>` asset sets in `App/Assets.xcassets` contain separate transparent 256×256 conversation portraits. [Artwork sources and prompts](../../Artwork/Dialogue/README.md) explain regeneration. The native UI draws the medallion and bubble; no wording is baked into images. `SkySpeaker` owns stable portrait asset IDs and names. `StarfallTheme.Dialogue` owns surface, brass, size and corner roles; `SkyDialogueBubble` owns layout. Board cast materials remain independent and unchanged.

To add a genuinely new speaker, add its stable case in `SkySpeaker`, its portrait asset, and a preview line in `studio.cast`. All hosts reuse it. Do not create another bubble implementation or runtime experiment flag. Existing portraits have one authored expression each; facial animation/recorded speech are outside this delivery.

## Check an edit

Run the hosted `SkyDialogueTests` using the Starfall scheme. They render every bundled script, reject malformed/duplicate content and missing/extra values, and check portrait packaging plus presentation lifecycle. Also use the studio at ordinary/largest text sizes and inspect actual phone-sized screenshots. For native layout/resource changes, run the repository's full affected checks, Debug/Release simulator builds and Core tests. A JSON edit can compile while still producing poor copy or wrapping; review it in the studio before delivery.

## Production events

`FallingSkyStore` selects guidance from committed clears, arrivals and gravity outcomes. `SkyDialogueLibrary` maps the committed next-shower phase/cadence into `timing.phase`, `timing.cadence` or `timing.combined`; Nova speaks warnings and recovery, with current counts refreshed at settlement. Existing phase/count rules and cadence timing remain Core-owned. The optional `guide.context` joins an explicit result with the current timing notice in the same bubble. Only designated transitions announce automatically. Settings/background reject stale completion speech through the store's existing generation guard.

The ordinary compact bubble receives the terrace's available footer height; its introduction scrolls before it can overlap native stars. Keep action controls outside that scrolling introduction. Actual VoiceOver acceptance remains an RC check.

Universal pressure uses `mass.*` copy and `guide.stellar-collapse` with Nova. Age and affected cells remain committed Core facts. Retained Dusk uses its existing copy only in retained skies.

`help.swap` and `help.trace` describe the [directional swap and one-gap contract](../../docs/design/TOUCH_INTENT.md); retain the horizontal-only rule and the distinction between selecting a trace and moving a neighbor.
