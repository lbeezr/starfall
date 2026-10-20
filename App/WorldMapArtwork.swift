import SwiftUI
import StarfallCore

/// A map-specific asset contract. Sources retain their complete transparent
/// canvas; registration is measured independently of the displayed point size.
struct WorldMapIslandArtwork: Identifiable, Equatable {
    let location: WorldLocation
    let damagedAsset: String
    let restoredAsset: String
    let registration: WorldMapIslandRegistration
    var id: WorldLocation { location }

    func asset(restored: Bool) -> String { restored ? restoredAsset : damagedAsset }
}

struct WorldMapIslandRegistration: Equatable {
    let sourceSize: CGSize
    let visibleBounds: CGRect
    let canvasInset: CGFloat
    let markerAnchor: CGPoint
    let leadingPort: CGPoint
    let trailingPort: CGPoint
    let upperPort: CGPoint
    let lowerPort: CGPoint
}

struct WorldMapConnection: Identifiable, Equatable {
    let source: WorldLocation
    let destination: WorldLocation
    var id: String { source.id + "-" + destination.id }
}

/// Declarative content is injectable for a native one-island production proof.
/// The renderer has no progression, persistence or navigation capability.
struct WorldMapContent: Equatable {
    let islands: [WorldMapIslandArtwork]
    let connections: [WorldMapConnection]

    static let production: Self = {
        let islands: [WorldMapIslandArtwork] = [
            island(.firstLight, name: "Lantern", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 21, y: 67, width: 1215, height: 1111),
                   marker: CGPoint(x: 0.50, y: 0.65), // Front wooden dock.
                   leading: CGPoint(x: 0.06, y: 0.56), trailing: CGPoint(x: 0.95, y: 0.56),
                   upper: CGPoint(x: 0.18, y: 0.37), lower: CGPoint(x: 0.53, y: 0.72)),
            island(.ribbonCrossing, name: "Ribbon", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 14, y: 33, width: 1231, height: 1178),
                   marker: CGPoint(x: 0.74, y: 0.66), // Front plaza, beyond the ribbon bridge.
                   leading: CGPoint(x: 0.08, y: 0.36), trailing: CGPoint(x: 0.95, y: 0.63),
                   upper: CGPoint(x: 0.18, y: 0.28), lower: CGPoint(x: 0.75, y: 0.88)),
            island(.kiteHarbor, name: "Kite", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 19, y: 86, width: 1218, height: 1074),
                   marker: CGPoint(x: 0.50, y: 0.63), // Clear front landing between the boats.
                   leading: CGPoint(x: 0.05, y: 0.51), trailing: CGPoint(x: 0.96, y: 0.52),
                   upper: CGPoint(x: 0.38, y: 0.37), lower: CGPoint(x: 0.50, y: 0.69)),
            island(.seedMoon, name: "Seed", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 16, y: 33, width: 1226, height: 1192),
                   marker: CGPoint(x: 0.53, y: 0.66), // Foreground stepping stones below the seed.
                   leading: CGPoint(x: 0.07, y: 0.52), trailing: CGPoint(x: 0.95, y: 0.51),
                   upper: CGPoint(x: 0.29, y: 0.27), lower: CGPoint(x: 0.53, y: 0.71)),
            island(.silverPools, name: "Silver", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 37, y: 31, width: 1179, height: 1173),
                   marker: CGPoint(x: 0.56, y: 0.72), // Foreground steps, clear of the pools.
                   leading: CGPoint(x: 0.07, y: 0.51), trailing: CGPoint(x: 0.94, y: 0.51),
                   upper: CGPoint(x: 0.35, y: 0.24), lower: CGPoint(x: 0.61, y: 0.80)),
            island(.frostfruitOrchard, name: "Frostfruit", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 26, y: 31, width: 1221, height: 1188),
                   marker: CGPoint(x: 0.50, y: 0.71), // Front path below the fruit and collecting trays.
                   leading: CGPoint(x: 0.055, y: 0.59), trailing: CGPoint(x: 0.95, y: 0.56),
                   upper: CGPoint(x: 0.88, y: 0.41), lower: CGPoint(x: 0.52, y: 0.75)),
            island(.sunwheelMill, name: "Sunwheel", source: CGSize(width: 1254, height: 1254),
                   body: CGRect(x: 23, y: 18, width: 1218, height: 1215),
                   marker: CGPoint(x: 0.50, y: 0.65), // Front stone path below the workbench.
                   leading: CGPoint(x: 0.10, y: 0.57), trailing: CGPoint(x: 0.94, y: 0.58),
                   upper: CGPoint(x: 0.78, y: 0.32), lower: CGPoint(x: 0.53, y: 0.71))
        ]
        return Self(
            islands: islands,
            connections: zip(islands, islands.dropFirst()).map { source, destination in
                WorldMapConnection(source: source.location, destination: destination.location)
            }
        )
    }()

    /// These families use measured 1254px canvases. `body` is the
    /// alpha>=128 pixel union of the two repair states; ports and the pin are
    /// optical attachment points chosen on their shared terrain. The renderer
    /// adds logical clearance without changing these source coordinates.
    private static func island(_ location: WorldLocation, name: String, source: CGSize, body: CGRect,
                               marker: CGPoint, leading: CGPoint, trailing: CGPoint,
                               upper: CGPoint, lower: CGPoint) -> WorldMapIslandArtwork {
        let registration = WorldMapIslandRegistration(
            sourceSize: source,
            visibleBounds: CGRect(x: body.minX / source.width, y: body.minY / source.height,
                                  width: body.width / source.width, height: body.height / source.height),
            canvasInset: 0.08, markerAnchor: marker, leadingPort: leading, trailingPort: trailing,
            upperPort: upper, lowerPort: lower
        )
        return WorldMapIslandArtwork(location: location, damagedAsset: "WorldMapIsland\(name)Damaged",
                                     restoredAsset: "WorldMapIsland\(name)Restored", registration: registration)
    }
}

struct WorldMapDestinationPresentation: Identifiable, Equatable {
    let location: WorldLocation
    let title: String
    let status: String
    let restored: Bool
    let canEnter: Bool
    var id: WorldLocation { location }
    var glyph: ObservatoryGlyph { restored ? .check : canEnter ? .story : .lock }

    init(location: WorldLocation, journey: WorldJourney) {
        self.location = location
        title = location.title
        status = location.status(in: journey)
        restored = journey.completed.contains(location)
        canEnter = journey.canEnter(location)
    }
}

struct WorldMapPresentation: Equatable {
    let destinations: [WorldMapDestinationPresentation]
    let selected: WorldLocation

    init(journey: WorldJourney, selected: WorldLocation) {
        destinations = WorldLocation.allCases.map { WorldMapDestinationPresentation(location: $0, journey: journey) }
        self.selected = selected
    }

    func destination(_ location: WorldLocation) -> WorldMapDestinationPresentation? {
        destinations.first { $0.location == location }
    }
}
