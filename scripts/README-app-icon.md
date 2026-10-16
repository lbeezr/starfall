# App icon

`starfall-app-icon.svg` is original procedural vector artwork for the Starfall prototype: an aqua/violet glass star on a moonlit background. The user approved this icon direction on 2026-10-16. It contains no third-party images, fonts, characters or text.

Run `bash scripts/generate-app-icon.sh` with Inkscape and ImageMagick installed to regenerate the checked-in 1024×1024, opaque RGB PNG. Neither tool is an app dependency or required for normal builds. The script only converts the original SVG; no generated-image service or credits are used.

The asset catalog uses the single-size universal iOS icon entry. Xcode derives smaller sizes. The image has no pre-rounded mask; the OS applies the final icon shape. Additional dark/tinted or layered Icon Composer variants are deliberately not claimed here.

Official format guidance checked 2026-10-16:
https://developer.apple.com/documentation/xcode/configuring-your-app-icon
https://developer.apple.com/design/human-interface-guidelines/app-icons

Validation performed: source SVG XML parsed; asset JSON parsed; PNG inspected at full resolution; PNG is 1024×1024 RGB without alpha. Asset catalog compilation and actual Home Screen rendering remain pending. The catalog is registered in the Xcode project; an actual build still needs to validate it. Do not infer App Store approval from these checks.
