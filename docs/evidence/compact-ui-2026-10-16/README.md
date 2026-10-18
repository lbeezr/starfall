# Compact falling-sky UI

**Historical screenshots partly retired October 17, 2026.** The compact HUD and Observatory supersede this routine paused-board frame. The largest-text capture remains as source-bound accessibility/layout evidence. [Retirement paths, hashes and Git recovery](../../SCREENSHOTS.md#october-17-2026--superseded-cast-and-routine-prototype-frames). These findings describe the original source, not current UI; start current visual work from [the selected reference](../../design/VISUAL_REFERENCE.md).

Native simulator checks, October 16, 2026. Gameplay uses shared `gameTitle`, `gameDetail`, spacing and 44-point button roles in StarfallTheme. One header and one unboxed forecast row replace the stacked title, subtitle, statistics and forecast panel. The tall board receives remaining portrait height, with a square minimum for short windows; the screen scrolls when needed. Instructions and active-round restart actions live in Settings. Terminal replay actions stay on the game screen.

The scene no longer draws square cell backgrounds or borders. Clearable jewels have a thin circular halo; dark-star growth-block cues remain. Jewel materials, deterministic seven-column rules and falling animations are retained. Vertical positions and native button padding both follow the taller board; jewels retain their aspect ratio.

Validation: 60 core tests passed; Release simulator build passed. On iPhone 18 Pro, all ten interaction tests and 16 hosted store tests passed, covering normal/manual/automatic play, rapid taps, growth, dark stars, win/loss, replay, background/relaunch, settings dismissal, largest text and system Reduce Motion. The final accessibility-only footer change stacks controls instead of breaking words; the compact playfield and largest-text tests plus 16 hosted tests passed again on iPhone 17e, and Release was rebuilt successfully. These focused tests also passed on the smaller phone before that correction.

`paused.png` is an inspected iPhone 18 Pro native screenshot showing the grid-free sky after one shower. `largest-text.png` is the inspected final iPhone 17e accessibility-XXXL screenshot, scrolled to the controls. The compact-playfield test requires board height above 60% of portrait screen height, visible primary controls and a successful native group clear.

VoiceOver labels, hints, rotor and native cell-button semantics remain in place. Actual VoiceOver speech/focus and physical-device haptic/audio feel were not exercised. Landscape and iPad visual acceptance remain pending.
