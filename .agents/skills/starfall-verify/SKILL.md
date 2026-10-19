---
name: starfall-verify
description: Select and run the existing checks for a Starfall change, or prepare development/RC evidence. Use for change validation and acceptance; not for general game explanations or phone delivery.
---
# Verify a Starfall change

Resolve the repository root with Git, even when invoked from a subfolder. Read root `AGENTS.md`, the guidance for changed boundaries, and [the verification matrix](../../../docs/ENGINEERING.md#verification-by-change). Paths in this skill are relative to its folder; commands run from the repository root.

Establish the tested revision/tree, changed paths and intended stage. Default ordinary iteration to development. Inspect the diff before choosing checks; a filename alone does not determine whether behavior, saved contracts or native inputs changed. Continue independent checks if one tool is unavailable and report that gap.

Use existing owners:

- Always run `python3 scripts/ci-hygiene.py` and `git diff --check`. The hygiene guard sees tracked paths: inspect new files too and rerun after explicit staging.
- For native matrix planning use `python3 scripts/native_test_plan.py --stage dev` (or `rc` when requested). It writes ignored `artifacts/native-test-*.json/txt`; do not copy test counts into this skill. Select affected tests for a bounded fix; a subset is not a full-matrix pass.
- Use installed Apple tooling for builds, hosted/UI tests and actual taps. `scripts/ci-simulator.sh` is disposable-runner orchestration, not a local convenience command. Use the local workflow in [ENGINEERING](../../../docs/ENGINEERING.md#working-loop); `scripts/README.md` explains existing exporters and platform checks.
- Apply [development/RC accessibility policy](../../../docs/DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage). Full actual VoiceOver is an RC gate; routine checks remain lightweight. Geometry/motion changes still need their native reproduction.

Record a concise source-bound result using [the report template](../../../docs/templates/REPORT.md): selected checks and why, exact commands/environment, pass/fail/skips, dirty build inputs, and remaining acceptance. Keep core, build, interaction, visual, animation, actual VoiceOver and device results distinct. Inspect retained screenshots before accepting appearance. Keep raw logs/xcresults in ignored artifacts/temp storage.

Do not install an app as a side effect of verification. Delivery intent belongs to the canonical updater workflow. Do not hide failures with retries, exclusions or quieter motion.
