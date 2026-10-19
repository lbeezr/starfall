---
name: starfall-maintenance
description: Audit a bounded Starfall area for stale experiments, unused code or duplicated ownership, and perform evidence-backed cleanup when requested. Use for maintenance audits and removals; not for new gameplay features or broad unsolicited rewrites.
---
# Maintain one Starfall boundary

Resolve the repository root and read root plus the affected local guidance. Establish the requested area and whether the task is an audit or an authorized fix; do not expand a cleanup into a feature redesign. Start with its README, [experiment status](../../../docs/EXPERIMENTS.md) and the relevant [engineering risk](../../../docs/ENGINEERING.md), not the entire archive.

Classify candidates as current runtime, retained compatibility/regression, historical reproduction, active comparison, proven unused, or unresolved. For each plausible change inspect direct and indirect consumers: callers, encoded fields/raw values, restore/replay migrations, Debug launch and accessibility IDs, Xcode target/resource membership, bundled asset names, wrappers and documented commands. Use Git history to establish why the boundary exists. Zero search hits alone do not establish safe deletion.

Prefer one demonstrated defect or duplicated owner. Historical Dusk, gravity, critical-mass readers and reset fixtures remain compatibility evidence; old names are not a removal signal. Sealed artwork, retained output/baselines and historical evidence payloads retain their documented owners/hashes.

For an audit, return a short ranked table with owner/status, consumers/evidence, uncertainty, benefit and smallest next action. For an authorized cleanup, implement one reviewable batch, run the [affected verification](../../../docs/ENGINEERING.md#verification-by-change), update the existing experiment/engineering owner, and record a recovery revision for removals. Preserve unrelated edits. An unresolved candidate stays documented; it does not justify an abstraction, dependency, permanent flag or additional app.

Report what was actually examined and measured. Line/word reduction alone is not a quality result; seed samples do not establish enjoyment. Do not create a second experiment database or a scheduled sweeping job.
