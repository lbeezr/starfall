# Repository scripts

Hygiene checks, native CI validation and app-icon export tooling.

## Start here

Run `python3 scripts/ci-hygiene.py` and `git diff --check` from the root. See [app icon export](README-app-icon.md) before regenerating branding; inspect `ci-simulator.sh` for its native environment requirements. The former icon SVG is historical.

`generate-celebration-audio.py` deterministically regenerates the two original short WAV celebration cues in `App/Audio`; no external service, samples or dependencies are used. Keep the generator and its bundled outputs together.
