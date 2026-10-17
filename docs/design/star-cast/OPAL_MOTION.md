# Opal: soft motion

User direction, October 17, 2026: she is squishy, can become a teardrop while falling, and rebounds less rigidly than the crystal cast. Her resting identity remains the selected round, milky Opal Orb. A personal name remains provisional.

Hypothesis: a soft fall/contact response makes her recognizable and warm without suggesting a different value, touch target or matching rule. Scope: Opal presentation only; no new ability, physics simulation, resource type or mechanic. Inspect native captures and ask for a reaction to the visible result; retain/tune this motion on that evidence. Human preference and replay appeal remain unverified.

Observable acceptance:

- Round at rest; narrower upper shoulder and fuller lower body in flight; one visible body at the landing handoff.
- Squash, gentle rebound and return to round fit the existing landing window. Face changes preserve deformation rather than resetting it halfway through.
- One child pose-action owner replaces competing contact/landing responses. Render, restart and interruption cancel deformations; no transient pose is saved.
- Quiet motion (Calm effects, system Reduce Motion, VoiceOver) presents the same committed result without this deformation. Native targets continue using shared board geometry.
- Existing crystal motions stay on their current path. The same committed Core score, star identities, preview and shower deadlines remain authoritative.

Implementation: five cached 2×3 SpriteKit warp grids, prewarmed by the scene. The falling mesh is static while the existing flight moves; the landed body interpolates through three bounded poses for 0.32 seconds within the 0.34-second landing window. Contact uses the existing response action key. No bitmap generation, IO, vertex allocation or new timer runs per frame. The body/face factory and its bounded texture cache stay shared.

Native motion capture is a separate hosted SpriteKit stage, composited over an opaque dark background before GIF encoding so translucent effects retain their intended appearance. Slowed preview frames illustrate motion; they do not establish complete in-game normal-speed playback, physical feel or human enjoyment.

[Current development acceptance](../../evidence/opal-main-integration-2026-10-17/README.md) records native motion, identity/handoff, restore and quiet checks. [Captured poses](../../evidence/opal-main-integration-2026-10-17/motion-poses.png) show her teardrop, squash, rebound and round rest; their source scope is recorded with the evidence. Human motion preference remains open.
