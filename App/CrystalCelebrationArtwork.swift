import SwiftUI
import StarfallCore

/// One bounded, eagerly prepared family. Animation only selects cached images.
@MainActor final class CrystalCelebrationArtwork {
    static let shared = CrystalCelebrationArtwork()
    struct Metric: Decodable {
        let character: String
        let advance: CGFloat
        let visible: Bool
    }
    struct Frame: Decodable {
        let x: Int, y: Int, w: Int, h: Int
        let width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat
        var sourceRect: CGRect { CGRect(x: x, y: y, width: w, height: h) }
        var isValid: Bool {
            [width, height, offsetX, offsetY].allSatisfy(\.isFinite)
                && width > 0 && height > 0 && width < 600 && height < 600
                && abs(offsetX) < 300 && abs(offsetY) < 300
        }
    }
    struct ViewSource: Decodable {
        let yaw: Int, asset: String, width: Int, height: Int
        let frames: [String: Frame]
    }
    struct Source: Decodable {
        let version: Int, capHeight: Int
        let glyphs: [String: Metric]
        let views: [ViewSource]
    }
    struct Sprite {
        let image: UIImage
        let frame: Frame
    }
    struct Run {
        struct Letter: Identifiable {
            let id: Int
            let key: String
            let pen: CGFloat
        }
        let text: String
        let letters: [Letter]
        let width: CGFloat
        let height: CGFloat = 240
        let baseline: CGFloat = 180
    }
    struct Family {
        let metrics: [String: Metric]
        let views: [Int: [String: Sprite]]
        let decodedAtlasBytes: Int
        func run(_ text: String) -> Run? {
            guard !text.isEmpty, text.count <= 40 else { return nil }
            var pen: CGFloat = 24, letters: [Run.Letter] = []
            for (index, character) in text.enumerated() {
                guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first else { return nil }
                let key = String(format: "u%04x", scalar.value)
                guard let metric = metrics[key], metric.character == String(character) else { return nil }
                if metric.visible { letters.append(.init(id: index, key: key, pen: pen)) }
                pen += metric.advance
            }
            return Run(text: text, letters: letters, width: pen + 24)
        }
        func award(_ value: Int) -> Run? {
            guard value > 0, String(value).count <= 6 else { return nil }
            return run("+\(value)")
        }
    }
    private let dataProvider: () -> Data?
    private let imageProvider: (String) -> UIImage?
    private(set) var loadAttempts = 0
    private(set) lazy var family: Family? = loadFamily()

    init(dataProvider: @escaping () -> Data? = { NSDataAsset(name: "CrystalDepthMetrics")?.data },
         imageProvider: @escaping (String) -> UIImage? = { UIImage(named: $0) }) {
        self.dataProvider = dataProvider; self.imageProvider = imageProvider
    }
    func prewarm() { _ = family }

    private func loadFamily() -> Family? {
        loadAttempts += 1
        guard let data = dataProvider(), data.count < 1_000_000,
              let source = try? JSONDecoder().decode(Source.self, from: data),
              source.version == 1, source.capHeight == 160,
              source.glyphs.count == 106, source.views.count == 15,
              Set(source.views.map(\.yaw)) == Set(stride(from: -35, through: 35, by: 5)),
              Set(source.views.map(\.asset)).count == 15 else { return nil }
        let visible = Set(source.glyphs.filter { $0.value.visible }.keys)
        guard visible.count == 105, source.glyphs["u0020"]?.visible == false,
              source.glyphs.allSatisfy({ key, metric in
                  guard metric.character.unicodeScalars.count == 1,
                        let scalar = metric.character.unicodeScalars.first else { return false }
                  return key == String(format: "u%04x", scalar.value)
                      && metric.advance.isFinite && metric.advance > 0 && metric.advance < 600
              }) else { return nil }
        var views: [Int: [String: Sprite]] = [:], decodedBytes = 0
        for view in source.views {
            guard (1...1024).contains(view.width), (1...1024).contains(view.height),
                  Set(view.frames.keys) == visible else { return nil }
            decodedBytes += view.width * view.height * 4
            guard decodedBytes <= 64 * 1024 * 1024,
                  let prepared = imageProvider(view.asset)?.preparingForDisplay(),
                  let atlas = prepared.cgImage, atlas.width == view.width, atlas.height == view.height else { return nil }
            var sprites: [String: Sprite] = [:]
            for (key, frame) in view.frames {
                guard frame.isValid, frame.x >= 2, frame.y >= 2, frame.w > 4, frame.h > 4,
                      frame.x <= view.width - frame.w - 2, frame.y <= view.height - frame.h - 2,
                      let cropped = atlas.cropping(to: frame.sourceRect) else { return nil }
                sprites[key] = Sprite(image: UIImage(cgImage: cropped), frame: frame)
            }
            views[view.yaw] = sprites
        }
        return Family(metrics: source.glyphs, views: views, decodedAtlasBytes: decodedBytes)
    }
}

/// Pure presentation sampling, with no callback, task or game-state ownership.
enum CrystalLetterMotion {
    static func yaw(age: TimeInterval, index: Int, quiet: Bool) -> Int {
        guard !quiet, age.isFinite else { return 0 }
        let t = max(0, age - Double(min(index, 12)) * 0.012) / 0.56
        guard t < 1 else { return 0 }
        func ease(_ x: Double) -> Double { 1 - pow(1 - min(1, max(0, x)), 3) }
        let angle = t < 0.5 ? -30 + 45 * ease(t * 2) : 15 * (1 - ease((t - 0.5) * 2))
        return max(-35, min(35, Int((angle / 5).rounded()) * 5))
    }
}

/// Layout stays fixed while per-letter frames change around their exported pivot.
struct CrystalGlyphLine: View {
    let run: CrystalCelebrationArtwork.Run
    let family: CrystalCelebrationArtwork.Family
    let capHeight: CGFloat
    let maximumWidth: CGFloat
    let age: TimeInterval
    let quiet: Bool

    var body: some View {
        let scale = min(capHeight / 160, max(1, maximumWidth) / run.width)
        Canvas { context, _ in
            for letter in run.letters {
                let yaw = CrystalLetterMotion.yaw(age: age, index: letter.id, quiet: quiet)
                if let sprite = family.views[yaw]?[letter.key] {
                    let f = sprite.frame
                    context.draw(Image(uiImage: sprite.image), in: CGRect(
                        x: (letter.pen + f.offsetX) * scale, y: (run.baseline + f.offsetY) * scale,
                        width: f.width * scale, height: f.height * scale))
                }
            }
        }
        .frame(width: run.width * scale, height: run.height * scale)
        .accessibilityHidden(true)
    }
}

/// Receives committed display values and receipt age; never awards points.
struct CrystalCelebrationLabel: View {
    let event: StarlightCelebration
    let tint: Color
    let width: CGFloat
    let showsTitle: Bool
    let age: TimeInterval
    let quiet: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        if !textSize.isAccessibilitySize, let family = CrystalCelebrationArtwork.shared.family,
           let award = family.award(event.collected),
           event.title == nil || family.run(event.title!) != nil {
            VStack(spacing: StarfallTheme.Spacing.compact) {
                if showsTitle, let title = event.title, let run = family.run(title) {
                    CrystalGlyphLine(run: run, family: family,
                        capHeight: StarfallTheme.Celebration.titleCapHeight,
                        maximumWidth: min(width, StarfallTheme.Celebration.titleMaximumWidth), age: age, quiet: quiet)
                }
                CrystalGlyphLine(run: award, family: family,
                    capHeight: event.title == nil ? StarfallTheme.Celebration.ordinaryAwardHeight : StarfallTheme.Celebration.specialAwardHeight,
                    maximumWidth: width, age: age, quiet: quiet)
            }
        } else {
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
}
