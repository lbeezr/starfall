# White-connector predictions before interaction

Familiar-agent prediction, 2026-10-17. Inspected only native `connection.jpg` and `pressure.jpg` with view_image. No Core, fixture code, expected outcomes, forecasts, README, accessibility hierarchy, or simulator interaction was consulted. These are predictions, not verified clears or cold human learning.

| Picture | Predicted usable families | Proposed first native action | Reason and opportunity cost |
|---|---|---|---|
| Connection | Amber via the two stars flanking white; aqua via the touching pair below white. Rose at bottom-left appears outside the white connection. | Tap the **left amber immediately left of white**. | Use white to bridge separated amber stars. It should consume both amber stars and white, leaving the two small aqua stars without that connector route. They may need growth/another match before clearing. Aqua is already directly connected to itself, so a future natural match seems more plausible than for the separated amber pair; this is a preference under uncertainty, not a proven optimal setup. |
| Pressure | Aqua to white's left, if its visibly larger size means value 2 plus white satisfies the threshold; rose on the right through its connected pair. Other left-column families appear separated and should not join merely because they share a column. | Tap the **large aqua at bottom-left, immediately left of white**. | Remove the base of the visibly full left tower and spend white for a local space gain. Choosing rose first would consume white while leaving that tower's base untouched. The rose pair appears to include one large and one small star, so it may remain independently clearable after the aqua choice; losing white need not foreclose every later rose clear. |

## Expected consumption and ambiguity

In Connection I predict choosing aqua instead would spend white plus the aqua pair, leaving amber without its bridge; gravity could change their positions. I do not predict that the rose star becomes part of either clear. Both alternatives look low on an otherwise empty board, so there is no visible urgency; holding is also reasonable, and the screenshot cannot establish which choice gives better future value.

In Pressure, the aqua choice should spend aqua and white, lower the left tower by one star, and preserve the rose stars. Rose-first should spend the rose group and white, foreclosing the connector-assisted aqua route while the aqua base still occupies its column. These predictions assume white participates in satisfying the existing value-three rule: the guide says it joins a neighboring family but does **not** explicitly state its threshold/scoring contribution. If white only connects colored stars without contributing value, the lone large aqua route is less certain. I cannot assign exact score rewards from the picture alone.

The white silhouette and black linked-loop/infinity-like mark distinguish the connector from colored families and from the dark star. The mark alone could mean unlimited reuse; Sunny's explicit “clearing spends the connector” resolves that interpretation. The guide also directs me to tap a colored star, so I would not tap white first. Pale outlines suggest ready groups but do not show which competing family owns white or preview all consumed cells. In Pressure, the apparent size difference matters to predicting whether rose survives as a legal independent clear; a native outcome check must confirm it.

## What the pictures cannot establish

Visible crowding is concrete: Pressure's left column reaches the top, while Connection has abundant space. The next landing, time until it, probability of that column receiving another star, actual overflow outcome, animation, automatic urgency, and optimal score/strategy are unknowable here. No assumption about the next landing is needed to prefer opening the full column, but that does not prove imminent loss. These two stills cannot establish replayability, human comprehension, enjoyment, or actual VoiceOver use.

## Observed first outcomes

Inspected only the two parent-supplied native outcome screenshots. Parent reports exactly the proposed first taps were executed and no Next shower occurred; I did not inspect hierarchy, Core, tests, or README or perform simulator input.

| Example | What the screenshot shows relative to prediction | Proposed next action, not executed |
|---|---|---|
| Connection | Score is 3. Both amber stars and white are gone; rose and the two aqua stars remain. The aqua stars have no ready outlines. This matches the predicted consumption and loss of the connector-assisted aqua route. | **Next shower**: no group appears ready, and there is abundant space. Invite a chance for growth/new connections rather than tap the undersized aqua pair. No particular incoming family or landing is assumed. |
| Pressure | Score is 3. Aqua and white are gone. The left tower has dropped one star and contains six remaining colored stars. Both rose stars remain, visibly outlined, with a larger lower star and smaller upper star. This matches the predicted space gain and preservation of an independently ready rose clear. | **Tap either remaining rose star**, preferably the lower large rose. Bank the still-ready group and open that separate column. This is now a straightforward available clear, not a second connector-allocation decision; it will not lower the six-high left column. |

The main uncertainty resolved is that the connector-assisted lone large aqua route really was legal in Pressure. The +3 result is consistent with a value-2 aqua plus a value-1 white; this does not establish a universal scoring contract beyond this observed example. Connection's +3 is likewise consistent with its two small amber stars plus white.

There was no major surprise in consumption. The important qualification remains: **spending white on aqua did not foreclose the rose clear**. It foreclosed use of that specific connector by rose, but the remaining rose pair already appears sufficient on its own. Calling this picture a mutually exclusive aqua-versus-rose reward would overstate the demonstrated tradeoff. Conversely, Connection visibly leaves the aqua pair without readiness after amber-first, so the immediate alternative there was actually lost.

Sunny's +3/space message confirms the result, but does not explicitly name the connector being spent. The disappearance of white and the unchanged remaining families provide that explanation visually. These stills support this particular prediction/outcome comparison, not cold comprehension or enjoyment. The six-high left tower in Pressure is visibly crowded, yet neither its next landing nor imminent overflow can be inferred.

Outcome screenshot paths:

- Connection: `/tmp/starfall-white-prediction-connection/1E3374C1-CD5A-4F00-832F-FC4FA52E883D.png`.
- Pressure: `/tmp/starfall-white-prediction-pressure/0525DAF1-B927-4BB9-A4EF-F68500CB81EA.png`.

## Final bounded verdict: two decisions per example

Only the two supplied final native screenshots were inspected. Parent reports the earlier choices were replayed to restore each example, then only Connection's Next shower and Pressure's rose clear were new actions. I performed no simulator interaction or hidden-source/hierarchy inspection.

- **Connection:** score remains 3; one amber star has arrived above the right aqua. Rose and the two small aqua remain, without ready outlines. This matches the bounded expectation that Next could supply a new star without guaranteeing an immediate clear. It does not demonstrate that my amber-first choice was optimal, nor that waiting on the original connector would have produced a better connection.
- **Pressure:** the rose pair is gone and score is 6, confirming a second +3 clear after aqua spent white. The left tower remains six high. This matches the prediction that rose remained independently clearable and that its removal would not lower that tower further.

**Readable ordering benefit:** Pressure shows a useful candidate for planning: spend the scarce connector on the otherwise isolated aqua base, while preserving the already sufficient rose pair for a separate clear. Both actual clears succeeded in that order. Rose-first would be expected to consume white and leave the isolated aqua base without that route; that reverse order remains a prediction, not a tested counterfactual in this two-decision scope. The benefit is preserving access to two useful clears, not choosing between two mutually exclusive score rewards. In Connection, spending white visibly removes the alternative aqua readiness; the later arrival did not establish that one initial family was strategically superior.

**Holding:** this bounded observation did not establish a concrete reward for holding white. Connection had abundant space, so holding was plausible, but possible future growth or connections were unknown rather than visible guaranteed benefits. Pressure's full tower supplied a visible reason to use aqua immediately, although the next landing and actual imminent overflow remained unknown. No waiting experiment or real-time urgency claim is justified.

**Recommendation: retain the isolated connector candidate for the next human comparison, with copy clarification before testing cold comprehension; do not adopt it from this evidence.** The finite connector creates a readable consumption consequence, and Pressure's aqua-then-rose sequence offers a more specific planning opportunity than simply taking either available reward. Counterevidence remains substantial: the second clear was straightforward, Connection did not reveal a clearly superior first choice, hold timing was not rewarded within scope, and a familiar agent's correct prediction is not evidence of human learning, enjoyment, or replayability.

My original uncertainty about white's threshold/scoring contribution remains part of the tested-copy finding. These outcomes are consistent with white contributing one in the observed clears, but the tested instruction did not explicitly state that contract. Parent copy refinements are outside this tested source and have not been assessed here. The linked-loop mark alone still risks suggesting reusable/infinite behavior; the tested “spends” sentence was necessary to my interpretation.

Final screenshot paths:

- Connection after Next: `/tmp/starfall-white-prediction-connection-next/964D3302-840F-42A2-B8A7-B9CA6A95CF4F.png`.
- Pressure after aqua then rose: `/tmp/starfall-white-prediction-pressure-order/73313DC4-9FFD-4CCA-84D9-2D361FE8F93E.png`.

Scope ends here: two decisions per example, no further actions recommended for this round.
