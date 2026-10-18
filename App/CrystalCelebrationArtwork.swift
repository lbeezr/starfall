import SwiftUI
import StarfallCore

/// A fixed material family. Both successful loading and failure are resolved once.
@MainActor final class CrystalCelebrationArtwork {
    static let shared = CrystalCelebrationArtwork()
    enum Title: String, CaseIterable {
        case brilliant = "Brilliant", constellation = "Constellation", square = "Square", cross = "Cross", relay = "Relay"
        var assetName: String { "Celebration" + rawValue }
        static func matching(_ event: StarlightCelebration) -> Title? {
            let title: Title
            let expected: String
            switch event.level {
            case .ordinary: return nil
            case .brilliant: title = .brilliant; expected = "Brilliant!"
            case .constellation: title = .constellation; expected = "Constellation!"
            case .recipe(let shape):
                title = shape == .square ? .square : .cross; expected = title.rawValue + "!"
            case .relay(let depth): title = .relay; expected = "\(depth)-clear relay!"
            }
            // Catalogue edits/localization retain the native string instead of stale English artwork.
            return event.title == expected ? title : nil
        }
    }
    struct Glyph: Identifiable {
        let id: String
        let image: UIImage
    }
    struct Family {
        let titles: [Title: UIImage]
        let glyphs: [Character: UIImage]
        func award(_ value: Int) -> [Glyph]? {
            let text = "+\(value)"
            guard value > 0, text.count <= 7 else { return nil }
            let images = text.enumerated().compactMap { position, character in
                glyphs[character].map { Glyph(id: "\(text):\(position)", image: $0) }
            }
            return images.count == text.count ? images : nil
        }
    }
    static let glyphOrder = Array("0123456789+-")
    private let imageProvider: (String) -> CGImage?
    private(set) var loadAttempts = 0
    private(set) lazy var family: Family? = loadFamily()

    init(imageProvider: @escaping (String) -> CGImage? = { UIImage(named: $0)?.cgImage }) {
        self.imageProvider = imageProvider
    }
    func prewarm() { _ = family }

    private func trimmed(_ source: CGImage, threshold: UInt8) -> UIImage? {
        guard let bounds = ArtworkRaster.alphaBounds(in: source, threshold: threshold),
              bounds.width > 8, bounds.height > 8,
              let image = source.cropping(to: bounds.insetBy(dx: -2, dy: -2)
                .intersection(CGRect(x: 0, y: 0, width: source.width, height: source.height))) else { return nil }
        return UIImage(cgImage: image)
    }
    private func loadFamily() -> Family? {
        loadAttempts += 1
        var titles: [Title: UIImage] = [:], glyphs: [Character: UIImage] = [:]
        for title in Title.allCases {
            guard let source = imageProvider(title.assetName), source.width <= 4096, source.height <= 2048,
                  let image = trimmed(source, threshold: 16) else { return nil }
            titles[title] = image
        }
        guard let atlas = imageProvider("CelebrationGlyphs"), atlas.width == 1448, atlas.height == 1086 else { return nil }
        // Authored source rows have optical spacing rather than uniform grid gutters.
        // These are source raster registrations, not a runtime text-layout heuristic.
        let rowEdges = [0, 400, 750, 1086]
        for (index, character) in Self.glyphOrder.enumerated() {
            let row = index / 4
            let frame = CGRect(x: (index % 4) * 362, y: rowEdges[row], width: 362, height: rowEdges[row+1] - rowEdges[row])
            guard let source = atlas.cropping(to: frame),
                  let image = trimmed(source, threshold: 160) else { return nil }
            glyphs[character] = image
        }
        return Family(titles: titles, glyphs: glyphs)
    }
}

/// Receives only a committed receipt and its material color; never owns gameplay timing.
struct CrystalCelebrationLabel: View {
    let event: StarlightCelebration
    let tint: Color
    let width: CGFloat
    let showsTitle: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        if !textSize.isAccessibilitySize,
           let family = CrystalCelebrationArtwork.shared.family,
           let digits = family.award(event.collected),
           event.title == nil || CrystalCelebrationArtwork.Title.matching(event) != nil {
            illustrated(family: family, digits: digits)
        } else {
            nativeText
        }
    }

    private func illustrated(family: CrystalCelebrationArtwork.Family, digits: [CrystalCelebrationArtwork.Glyph]) -> some View {
        VStack(spacing: StarfallTheme.Spacing.compact) {
            if showsTitle, let title = CrystalCelebrationArtwork.Title.matching(event), let image = family.titles[title] {
                if case .relay(let depth) = event.level {
                    Text("\(depth)-clear").font(StarfallTheme.Typography.celebrationRelayCount).foregroundStyle(tint)
                }
                material(image)
                    .frame(width: min(width, StarfallTheme.Celebration.titleMaximumWidth),
                           height: StarfallTheme.Celebration.titleHeight)
            }
            HStack(spacing: StarfallTheme.Celebration.glyphSpacing) {
                ForEach(digits) { glyph in
                    material(glyph.image)
                        .frame(width: glyphHeight * glyph.image.size.width / glyph.image.size.height,
                               height: glyphHeight)
                }
            }
        }
    }
    private var glyphHeight: CGFloat {
        event.title == nil ? StarfallTheme.Celebration.ordinaryAwardHeight : StarfallTheme.Celebration.specialAwardHeight
    }
    private func material(_ image: UIImage) -> some View {
        CrystalCelebrationMaterial(image: image, tint: tint)
    }
    private var nativeText: some View {
        VStack(spacing: StarfallTheme.Spacing.compact) {
            if showsTitle, let title = event.title {
                Text(title).font(StarfallTheme.Typography.celebrationTitle)
                    .foregroundStyle(tint).fixedSize(horizontal: false, vertical: true)
            }
            Text("+\(event.collected)").font(StarfallTheme.Typography.celebrationAward)
                .foregroundStyle(StarfallTheme.Colors.textPrimary).monospacedDigit()
        }
    }
}

/// The authored grayscale faces remain the light map. Refraction is masked by
/// their luminance, so light catches individual faces instead of filling the
/// silhouette with one color. Static material; receipt motion has its own owner.
struct CrystalCelebrationMaterial: View {
    let image: UIImage
    let tint: Color

    private var source: some View { Image(uiImage: image).resizable().scaledToFit() }

    var body: some View {
        ZStack {
            source.colorMultiply(tint)
            source
                .overlay {
                    LinearGradient(colors: StarfallTheme.Celebration.refraction,
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                        .blendMode(.color)
                }
                .compositingGroup()
                .mask { source.contrast(1.6).brightness(-0.15).luminanceToAlpha() }
                .opacity(0.78)
            // A narrow pearl highlight keeps the brightest cut edges luminous
            // without the old uniform white wash over the whole material.
            source.contrast(3).brightness(-0.55)
                .blendMode(.screen).opacity(0.25)
        }
        .compositingGroup()
        .mask { source }
        .accessibilityHidden(true)
    }
}
