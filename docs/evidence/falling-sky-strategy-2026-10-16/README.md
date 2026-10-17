# Falling-sky decision-depth baseline

October 16, 2026. Core gameplay tree: published commit `2411de613ead162960092ed37d38c158631f9ab7`. This adds an offline analysis tool and planning documents; it does not change game rules or rendering.

Reproduce from repository root:

```sh
swiftc -O Sources/StarfallCore/*.swift tools/sample-falling-sky-balance.swift -o /tmp/starfall-balance-sample
/tmp/starfall-balance-sample > /tmp/starfall-strategies.json
```

`strategies.json` records six policies across seeds 0...199, up to 60 showers. Every sampled round ended before the cap. A policy may clear once after each shower, except `all`, which clears all available groups in canonical order. The clear-all loop is bounded to 25 iterations; a legal clear removes at least two of 49 cells, so it cannot reach that bound without stopping first. Neither policy models human reaction or animation input gates. Pace settings change wall-clock time, not this event-based simulation.

| Policy | Mean starlight | Mean showers survived | Match-ready states with multiple groups |
| --- | ---: | ---: | ---: |
| No clears | 0 | 19.68 | Not applicable |
| Clear all available | 62.09 | 26.45 | 6.67% |
| First group | 58.52 | 26.21 | 9.61% |
| Largest group | 58.48 | 26.14 | 9.48% |
| Reduce column pressure | 59.70 | 26.63 | 9.68% |
| Preview-aware pressure | 59.70 | 26.63 | 9.68% |

Pressure is the sum of squared column heights after the candidate clear. Preview-aware pressure first avoids immediate overflow in the announced next shower, then minimizes pressure. It sees landing columns, which the product hides, so it is an upper-bound diagnostic, not a player model. Future shower generation can depend on the resulting board; shared seeds do not guarantee identical future previews across policies.

The first-group policy encountered 11 states across all rounds where one clear avoided next-shower overflow and another did not. Those states are included in the multiple-group count. The early-match fix improved activity, but simultaneous choices remain uncommon, and the two simple group-order policies perform almost identically. These observations motivate a mixed-color distribution experiment and human comparison, not a new score bonus, power-up or move cost.

No simulation establishes comprehension, enjoyment, physical feel, optimal play or human difficulty. `strategies.json` contains totals and example seeds, not participant results.
