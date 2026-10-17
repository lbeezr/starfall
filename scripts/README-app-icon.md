# App icon

The current icon is **Playful Tumble**: Spark falling along a curved lavender/aqua trail above soft sanctuary clouds. The user selected the rightmost falling-icon concept on October 17, 2026 and authorized adoption. `Artwork/AppIcon/playful-tumble-source.png` is a standalone AI-generated refinement of that selected concept, not a pixel-identical crop of the comparison strip. It contains no text or third-party character assets.

Run `bash scripts/generate-app-icon.sh` on macOS to export the checked-in 1024×1024 opaque sRGB PNG. The small developer-only Swift exporter uses system CoreGraphics/ImageIO, flattens onto midnight, and resamples the original square source. It is not an app target dependency. Keep the source artwork and exporter as the authoritative pair; do not regenerate the old glass SVG over the current icon.

The asset catalog retains its existing single-size universal iOS entry and filename. Xcode derives smaller sizes. The source has no rounded mask; the OS applies it. Dark/tinted or layered Icon Composer variants are not supplied. The former `scripts/starfall-app-icon.svg` remains historical original vector art, no longer the active export source.

See `docs/evidence/playful-tumble-icon-2026-10-17/README.md` for source-bound native validation and remaining limits. No gameplay, launch screen, cover screen, bundle identity, permissions, SDKs or monetization changes are part of this icon adoption.
