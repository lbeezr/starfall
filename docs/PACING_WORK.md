# Ship the user-selected Starfall rhythm

**Status:** B adoption and delivery in progress · **Owner:** current implementer · **Updated:** October 17, 2026

The seven implementation tasks produced a locally verified comparison. The user then selected B for the normal game and explicitly requested one PR, a merge to remote main and an in-place update of the existing phone app. No further A/B session is required.

**Next action:** Verify the production promotion, publish and merge the coherent PR, then use the existing one-app updater to deliver exact merged main. [Adoption contract](design/PACING_ADOPTION.md).

The Core, Store, cue, tooling and source-bound simulator evidence remain in their focused commits. The export-only selector is retired. Existing saves keep their contracts; new brisk skies use the announced cycle. User preference/physical feel remain unmeasured and must not be inferred from adoption authorization.

- [x] Production Core/UI promotion and compatibility checks complete; source-bound [adoption evidence](evidence/pacing-adoption-2026-10-17/README.md).
- [ ] PR published, reviewed and merged into main.
- [ ] Exact main installed in place as `com.starfall.prototype`; retained save and build identity checked.

Historical comparison evidence: [simulator acceptance](evidence/pacing-acceptance-2026-10-17/README.md) and [tooling](evidence/pacing-tools-2026-10-17/README.md). New production/device evidence must remain source-bound separately.
