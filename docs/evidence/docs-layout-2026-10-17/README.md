# README and visual-reference layout review

**Result:** Verified in local HTML preview · **Date:** October 17, 2026

Rendered and inspected the root README and visual reference before and after editing at 1,100 × 950 and 390 × 950 CSS pixels. The final pages use smaller previews, one cast overview and a compact identification table. Debug/provenance and motion-sheet instructions remain available through disclosures.

## Source and method

Base commit: `33a5c1672b7fd2aa12e6f9b0aaf0563c0a2ea4d4`. Both documents were tested as working-tree files, not a clean published commit. Earlier documentation/template work was also dirty; no app sources, images, resources or build configuration changed in this review. The complete tested Markdown is retained by hash:

- `README.md`: `353fbb97e06cd820e2d4621f7c6ddb62e25e25a2f8cc17c685bc43782d345626`
- `docs/design/VISUAL_REFERENCE.md`: `f24a2711c593b021c2973fedb5188356cca4c2f963121f90182df7f243340cb2`

Used bundled `marked` to render Markdown with raw HTML, local assets and an explicitly supplied GitHub-style stylesheet. Playwright drove installed Google Chrome **155.0.8059.85** headlessly, offline; no hosted service or user browser session was used.

Reproduction while local artifacts remain:

```sh
NODE_PATH=/Users/lbeezr/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  node artifacts/docs-review/render.cjs after
```

The renderer, generated HTML, before/after full-page PNGs and layout measurements are retained under ignored `artifacts/docs-review/`. This is a local review fixture, not a new runtime or repository dependency.

## Observed results

| Check | Result |
| --- | --- |
| Desktop and narrow screenshot review | Inspected both pages; repeated tiny cast poses and dense introductory text prompted revisions. Final captures show a compact cast table and matching 144-pixel screen previews. |
| Image loading | Every embedded image decoded at both widths. |
| Layout measurements | No horizontal page or table overflow at either width. Disclosures expanded without page overflow or missing images. Code blocks retain intentional horizontal scrolling. |
| Content and local paths | Asset/evidence links resolve; recognition, scoring and verification limits remain visible. Full motion sheets remain linked. |
| Repository checks | `python3 scripts/ci-hygiene.py` and `git diff --check` passed. |

## Limits and next action

This verifies the local browser layout, **not exact GitHub/Codex renderer parity**. Narrow browser screenshots are not physical-phone validation. No app behavior, animation, actual VoiceOver or native build was tested; this batch changes documentation only. Small previews support overview reading; linked full-size files support detailed visual review.

Next: check the published documents in the intended Markdown viewer when available. No additional gameplay or art adoption follows from this review.
