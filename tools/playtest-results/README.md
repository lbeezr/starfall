# Playtest observations

A blank observation CSV, schema and local summary tooling with regression checks.

## Start here

Follow [the playtest results protocol](../../docs/design/PLAYTEST_RESULTS.md). Keep actual observations separate from examples; inspect `summarize.py` usage and run `python3 -m unittest discover -s tools/playtest-results` after changing its behavior. Do not invent participant results.

## Current falling-sky game

Start with [the moderator worksheet](FALLING_SKY_SESSION.md). `falling_sky.py` generates an entirely blank JSON session or a standalone offline form, validates observations and summarizes exact build/settings cohorts. It separates human/synthetic evidence, people/sessions, offered/missing Opal choices, prediction help and actual replay opportunities. No app telemetry, network or automatic tuning.

```sh
python3 tools/playtest-results/falling_sky.py new /tmp/starfall-session.json
python3 tools/playtest-results/falling_sky.py form /tmp/starfall-moderator.html
python3 tools/playtest-results/falling_sky.py summarize /tmp/starfall-session.json
```

`falling-sky-session.html` is the source template; generate it with `form` before opening. The Python contract supplies its fields/defaults. Browser visual/interaction review remains unverified; the generated JavaScript has a syntax check and the contract has regression coverage. The original CSV/schema/summarizer above remain specifically for the historical 70/18 puzzle and must not accept current falling-sky observations. Actual records/notes belong in ignored artifacts or another chosen local folder; checked-in tests use fictional temporary records only.
