# Build and privacy configuration

Clean-edition build settings and the app privacy manifest.

## Start here

Preserve fully offline gameplay and the clean edition; optional rankings use Apple GameKit only. Build-setting or resource changes require Debug/Release and membership checks; see [repository instructions](../AGENTS.md).

`GameCenter.entitlements` enables only optional Apple Game Center rankings. `Clean.xcconfig` applies it in Debug and Release; no ads/IAP entitlement or external SDK is introduced. Gameplay and saves remain usable offline. Live Game Center requires the [matching App ID, provisioning and leaderboard setup](../docs/design/GAME_CENTER.md#apple-setup-required-before-live-acceptance).
