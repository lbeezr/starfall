# Native interaction tests

XCTest flows exercising the app through native controls on Apple tooling.

## Start here

Run relevant flows through the Starfall scheme. Keep bounded condition-based waits and isolated test saves. Report actual VoiceOver and full-motion observations separately from automation.

`SkyLeaderboardInteractionTests` uses `--starfalls-reset --rankings-review=<state>` to inject an isolated Debug transport. It checks Friends/Global, cached/uncached offline states, signed-out play, background/return and large-text dismissal without contacting Game Center. These checks cannot establish real Apple authentication or submission.
