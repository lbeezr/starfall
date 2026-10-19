# Nebula Cradle: five independently movable planes

This folder holds the first generated layer kit for the [nightscape browser study](../index.html). The five PNGs were generated from the original Nebula concept with built-in Imagegen; [manifest.json](manifest.json) retains exact prompts, source paths and hashes. These are concept assets, not packaged native resources.

| Plane | Purpose | Browser treatment |
| --- | --- | --- |
| Deep space | Continuous quiet dark background | Opaque, stationary |
| Distant haze | Soft depth behind the nearer masses | 28% opacity, ±2px drift |
| Left cloud | Main recognizable nebula form | 86% opacity; landscape side anchor, portrait upper corner |
| Right cloud | Opposing mass with separate movement | 84% opacity; landscape side anchor, portrait lower corner |
| Near wisps | Faint additional edge atmosphere | 18% opacity; up to ±7px horizontally and ±6px vertically |

The four overlays have alpha channels; the base is opaque. Dimensions are 1448×1086 except left cloud at 1447×1087. The generated clouds extend farther inward than requested, and “near wisps” contains substantial corner masses. Layout, opacity and a short fade at exposed portrait layer edges compensate in this study; the art is not certified as a seamless interchangeable production kit. Portrait needs separate anchors to preserve identity without filling the field.

All five can be independently hidden. Motion uses fixed images and bounded CSS transforms; the game field and HUD do not move. System Reduce Motion disables animation, and hiding the page or scenery pauses it. The native app has not adopted these layers; texture memory, seams during native motion, accessibility and device performance remain unverified. See the parent report for inspected compositions and browser checks.
