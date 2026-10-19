import SwiftUI
import StarfallCore

/// Registered paint regions, in source-image fractions. Both complete paintings
/// share one camera; reveals are keyed by durable completion, never animation.
struct WorldMapLayout {
    static func region(_ location: WorldLocation, in size: CGSize) -> CGRect {
        let regions: [CGRect] = [
            .init(x: 0, y: 0.705, width: 0.386, height: 0.225),
            .init(x: 0.375, y: 0.744, width: 0.307, height: 0.17),
            .init(x: 0.683, y: 0.728, width: 0.317, height: 0.19),
            .init(x: 0.71, y: 0.511, width: 0.28, height: 0.2),
            .init(x: 0.356, y: 0.511, width: 0.345, height: 0.21),
            .init(x: 0, y: 0.508, width: 0.363, height: 0.201),
            .init(x: 0, y: 0.314, width: 0.36, height: 0.19),
            .init(x: 0.354, y: 0.302, width: 0.306, height: 0.205),
            .init(x: 0.66, y: 0.32, width: 0.34, height: 0.2),
            .init(x: 0.704, y: 0.096, width: 0.296, height: 0.23),
            .init(x: 0.377, y: 0.119, width: 0.295, height: 0.179),
            .init(x: 0.015, y: 0.124, width: 0.361, height: 0.187)
        ]
        let r = regions[location.number - 1]
        return CGRect(x: r.minX * size.width, y: r.minY * size.height,
                      width: r.width * size.width, height: r.height * size.height)
    }
    static func route(after location: WorldLocation, in size: CGSize) -> Path {
        let points: [(CGPoint, CGPoint, CGPoint)] = [
            (.init(x:0.29,y:0.835), .init(x:0.36,y:0.825), .init(x:0.43,y:0.832)),
            (.init(x:0.65,y:0.84), .init(x:0.70,y:0.83), .init(x:0.75,y:0.84)),
            (.init(x:0.92,y:0.76), .init(x:0.97,y:0.74), .init(x:0.87,y:0.675)),
            (.init(x:0.76,y:0.635), .init(x:0.7,y:0.62), .init(x:0.63,y:0.64)),
            (.init(x:0.40,y:0.58), .init(x:0.36,y:0.575), .init(x:0.29,y:0.60)),
            (.init(x:0.065,y:0.55), .init(x:0.045,y:0.51), .init(x:0.09,y:0.46)),
            (.init(x:0.27,y:0.415), .init(x:0.31,y:0.39), .init(x:0.38,y:0.40)),
            (.init(x:0.61,y:0.405), .init(x:0.65,y:0.41), .init(x:0.70,y:0.41)),
            (.init(x:0.92,y:0.36), .init(x:0.95,y:0.32), .init(x:0.94,y:0.28)),
            (.init(x:0.70,y:0.20), .init(x:0.67,y:0.19), .init(x:0.63,y:0.20)),
            (.init(x:0.38,y:0.20), .init(x:0.36,y:0.19), .init(x:0.32,y:0.188))
        ]
        guard location.number <= points.count else { return Path() }
        let p = points[location.number - 1]
        func scaled(_ point: CGPoint) -> CGPoint { .init(x: point.x * size.width, y: point.y * size.height) }
        return Path { path in path.move(to: scaled(p.0)); path.addQuadCurve(to: scaled(p.2), control: scaled(p.1)) }
    }
}

struct WorldMapPainting: View {
    let journey: WorldJourney
    let selected: WorldLocation
    let traveler: WorldLocation
    let quiet: Bool
    let select: (WorldLocation) -> Void
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                painting("WorldMapDamaged")
                painting("WorldMapRestored")
                    .mask {
                        ZStack {
                            ForEach(WorldLocation.allCases) { location in
                                let region = WorldMapLayout.region(location, in: size)
                                RoundedRectangle(cornerRadius: region.width * 0.18)
                                    .fill(.white).frame(width: region.width, height: region.height)
                                    .position(x: region.midX, y: region.midY)
                                    .opacity(journey.completed.contains(location) ? 1 : 0)
                                WorldMapLayout.route(after: location, in: size)
                                    .stroke(.white, style: StrokeStyle(lineWidth: size.width * 0.045, lineCap: .round))
                                    .opacity(journey.completed.contains(location) ? 1 : 0)
                            }
                        }.blur(radius: size.width * 0.012)
                    }
                    .animation(quiet ? nil : .easeInOut(duration: 0.9), value: journey.completed)
                ForEach(WorldLocation.allCases) { location in
                    let region = WorldMapLayout.region(location, in: size)
                    if !journey.canEnter(location) {
                        // The damaged painting supplies the actual broken architecture;
                        // this soft veil conceals its unreached details without UI badges.
                        Ellipse()
                            .fill(RadialGradient(colors: [StarfallTheme.Colors.skyTop.opacity(0.88),
                                                         StarfallTheme.Colors.skyTop.opacity(0.7), .clear],
                                                 center: .center, startRadius: 0, endRadius: region.width * 0.66))
                            .frame(width: region.width * 1.15, height: region.height * 1.12)
                            .blur(radius: size.width * 0.016)
                            .position(x: region.midX, y: region.midY)
                            .accessibilityHidden(true)
                    }
                    Button { select(location) } label: {
                        Color.clear.frame(width: max(44, region.width), height: max(44, region.height))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(location.title)
                    .accessibilityValue(location.status(in: journey))
                    .accessibilityAddTraits(location == selected ? .isSelected : [])
                    .accessibilityIdentifier("world.node.\(location.id)")
                    .position(x: region.midX, y: region.midY)
                }
                let home = WorldMapLayout.region(traveler, in: size)
                Image(uiImage: StarCast.image(for: .init(kind: .amber)))
                    .resizable().scaledToFit().frame(width: 28, height: 28)
                    .shadow(color: StarfallTheme.Ceremony.gold.opacity(0.6), radius: 5)
                    .position(x: home.midX, y: home.maxY - home.height * 0.12)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }.clipped()
    }
    private func painting(_ name: String) -> some View {
        Image(name).resizable().scaledToFit().allowsHitTesting(false).accessibilityHidden(true)
    }
}
