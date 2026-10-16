# MVP acceptance checklist

## Automated core
- Same seed produces same board and subsequent refills
- Orthogonal same-kind flood fill; no diagonal connection
- Groups smaller than three and out-of-board taps do not spend moves
- A successful tap clears its complete group and spends one move
- Surviving column order remains stable under downward gravity
- Board refills to 49 cells
- Target reached on last move wins; terminal states reject taps
- Every live board has a legal move after bounded free recovery
- Save round trip preserves RNG continuation; invalid state is rejected

## Apple-platform manual checks (not yet executed)
- Play from menu, tap valid/invalid groups, verify counter and fall animation
- Rapid repeated taps during clear/settle do not spend extra moves
- Win at 70+; lose below 70 with zero moves; restart both
- Open/dismiss settings and menu; resume same game
- Background during clear and restore app; no frozen input or lost committed move
- Kill/relaunch after a move; restore exact board/counters
- Enable VoiceOver before play and during an animation; perform several clears
- Reduce Motion/Calm Effects produce immediate state updates without motion
- Sound toggle defaults off and changes optional system tap sound
- Small and large iPhone and iPad layouts, landscape iPad, large text
- Clean build contains no ad/purchase UI, SDK, tracking or network requests

Target and move count are initial tuning values, not validated commercial balance. Device accessibility and aesthetic quality remain acceptance work until a simulator/device run is inspected.
