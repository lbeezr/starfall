---
name: starfall-ci-triage
description: Diagnose a failed, cancelled or unexpectedly slow Starfall GitHub Actions run using exact source, job logs and bounded reproduction. Use for CI investigation; not for routine copy edits or a request merely to run local tests.
---
# Triage Starfall CI

Resolve the repository root; read root and `scripts/AGENTS.md`, then the current workflow and only the helpers implicated by the failure. Use [script ownership](../../../scripts/README.md) and [current engineering risks](../../../docs/ENGINEERING.md) as routes, not an instruction to reread the historical archive.

1. Establish repository, run ID, source SHA, event, attempt and job IDs. If the user supplied only a failure description, inspect recent runs to find matching evidence. Preserve cancelled-run assertions and distinguish attempt metadata from the full run history.
2. Read job steps/logs before changing code. Separate inventory/boot, compilation, core/hosted/UI assertions, timeout, cancellation, cleanup and export failures. Use stage receipts from `simulator-command.py`; missing artifacts or a cancelled upload do not erase earlier failures. State what remains unknown.
3. Match local source and Xcode/OS/simulator where available. Reproduce the smallest failing case, then representative sibling/boundary cases. For UI setup, inspect current dialogue/control IDs, scroll readiness and fixture ownership. Retained Dusk/aging/gravity checks cannot assume fresh survival generates historical mechanics.
4. Fix a demonstrated cause within authorized scope and run affected checks. Reuse the existing native matrix/export/lifecycle owners. Preserve count and zero-skip gates, timeouts and primary-versus-cleanup failures. Do not relax assertions, force reduced motion or add blanket retries. Record independent remaining failures rather than blocking a verified correction on unrelated work.
5. For slowness, compare phase durations on equivalent sources/environments. Separate completed-pass time from failed/cancelled elapsed time. Do not infer billed cost or successful-run medians from a sample with no passes. Justify a cache, concurrency, timeout or trigger change with measured cause and unchanged coverage.

Return a compact diagnosis: exact run/source/attempt links, categories and evidence, reproduction conditions, verified correction or next experiment, and remaining risks with owner/trigger in ENGINEERING. Use [the report template](../../../docs/templates/REPORT.md), retaining small structured metadata and disposable raw logs. Call remote CI healthy only after a complete passing development matrix. Do not dispatch/rerun paid or manual CI, broaden triggers, or install on a phone incidentally.
