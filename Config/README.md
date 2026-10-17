# Build and privacy configuration

Clean-edition build settings and the app privacy manifest.

## Start here

Preserve the offline, SDK-free edition. Build-setting or resource changes require Debug/Release and membership checks; see [repository instructions](../AGENTS.md).

`Starfall-Info.plist` supplies `StarfallBuildID` from the build setting; local device delivery injects the runtime fingerprint before signing. The bundle identifier and ordinary save suite remain stable.

`Clean.xcconfig` selects the app's `LaunchScreen.storyboard`; its named dark color also backs the first SwiftUI frame. Keep generated launch-screen settings absent so there is only one launch declaration.

