# GitHub collaboration

Issue and pull-request templates keep review focused; workflows run repository checks.

## Start here

Start with [the writing process](../docs/WRITING.md). Edit workflows only when the validation behavior needs to change.

The [factory contract](../docs/AGENT_FACTORY.md#completion-follows-github) uses native PR closing references and Project Item closed automation. The task/PR templates make completion explicit; no additional Actions workflow or required check is introduced.

[game-workstreams.json](game-workstreams.json) owns the workstream, role and optional label catalogue. [Tracking guidance](../docs/GAME_WORKSTREAMS.md) separates task ownership, supporting expertise, evidence and resource gaps; the [readable role catalogue](../docs/GAME_ROLE_CATALOG.md) is generated from it. The export is read-only and does not install live labels or configure a Project.
