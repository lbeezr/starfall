# Starfall repo skills

Load the workflow that matches the task: [verify a change](starfall-verify/SKILL.md), [diagnose CI](starfall-ci-triage/SKILL.md), or [audit a bounded area](starfall-maintenance/SKILL.md). For UI concepts, HUDs and interactive scenery, [produce reusable native components](starfall-ui-production/SKILL.md) before expanding an asset family. Root and local `AGENTS.md` own invariants; [ENGINEERING](../../docs/ENGINEERING.md#verification-by-change) owns check selection.

For a requested factory/swarm or substantial parallel delivery, [starfall-factory](starfall-factory/SKILL.md) coordinates bounded independent subagents and continuous integration under the [factory contract](../../docs/AGENT_FACTORY.md). Small fixes remain single-agent work. Its optional offline graph/closure helper adds no CI requirement.

These skills do not change personal/plugin settings, dispatch CI or authorize delivery. The [maintenance evidence](../../docs/evidence/repo-maintenance-2026-10-19/IMPLEMENTATION.md) records the original skills' validation and limits; [factory evidence](../../docs/evidence/agent-factory-2026-10-22/README.md) tracks the new workflow separately.
