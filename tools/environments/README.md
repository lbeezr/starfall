# Observatory verification tools

The Observatory now lives in production: [geometry](../../App/ObservatoryGeometry.swift), [environment](../../App/ObservatoryEnvironment.swift), [game view](../../App/FallingSkyView.swift) and [native checks](../../UITests/ObservatoryInteractionTests.swift). There is no parallel lab implementation. The earlier palette/cosmic/landing exporters and duplicate Swift templates were retired on adoption; their source-bound exports and reports remain historical evidence.

```sh
python3 tools/environments/prepare-observatory-review.py
```

This prints a snapshot of tracked working-tree bytes, with HEAD, dirty status and SHA-256 hashes in `ENVIRONMENT-LAB-SOURCE.json`. Stage newly added source/resources before exporting. It makes no runtime, bundle, rule or save overrides. Build the printed `Starfall.xcodeproj` with scheme `Starfall`; normal launches use the actual production route and bundle `com.starfall.prototype`.

Debug-only review: `--starfalls-reset --observatory-review` supplies the real cast in a deterministic sparse sample; add `--observatory-dense` for a full terrace. Those arguments cannot select a fixture in Release. Use only a disposable simulator for reset/review runs. Normal survival/First Light and previous saves use the existing production initializer. The obsolete `skyEnvironment` preference is ignored; it cannot change scenery or retained game state.

[Production strategy](../../docs/design/environments/PRODUCTION.md), [adoption evidence](../../docs/evidence/observatory-adoption-2026-10-17/README.md), and [original native proof](../../docs/design/environments/landing-native-01/README.md) separate current acceptance from historical work. Exact artwork prompts remain in the design record; four packaged imagesets own runtime assets. Raw logs, traces and movies stay under ignored `artifacts/`.

`export_committed_tree` captures a validated Git archive at an explicit commit and hashes its inputs. The [gravity trial](../mechanics/README.md#magnetic-collision-and-captive-orbit) uses it to keep current-main edits and normal saves outside an isolated candidate.

The integrated runtime uses `App/LandingGeometry.swift` and `App/LandingEnvironment.swift`. The [production set](../../docs/design/environments/production-set/README.md) records asset provenance and acceptance; tools here are authoring support.
