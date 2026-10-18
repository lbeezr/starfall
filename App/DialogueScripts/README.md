# Write a character conversation

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

Keep counts and gameplay facts in values supplied from committed state; do not put random choices, scoring, timers, save data or branching conditions into JSON. Avoid claims about a storm or changed pace unless that rule actually applies in the current game.

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
