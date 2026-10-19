import Foundation

/// Cosmetic destinations preserve historical raw values; they never select game rules.
enum LandingPlace: String, CaseIterable, Identifiable {
    case moonwake = "observatory", nebula = "cloudsea", ringdrift = "hearth", garden = "grotto", shatterlight = "archive"
    static let preferenceKey = "landingPlace"
    static func restored(_ value: String) -> Self { Self(rawValue: value) ?? .moonwake }
    var id: String { rawValue }
    var title: String {
        switch self {
        case .moonwake: "Moonwake"
        case .nebula: "Nebula Cradle"
        case .ringdrift: "Ringdrift"
        case .garden: "Night Garden"
        case .shatterlight: "Shatterlight Reach"
        }
    }
    var detail: String {
        switch self {
        case .moonwake: "A pearl moon and a little sail crossing the dark"
        case .nebula: "Young light sheltered in violet clouds"
        case .ringdrift: "Quiet passage beside a distant planet's rings"
        case .garden: "Open night above an alien canopy"
        case .shatterlight: "A remembered world, scattered among the stars"
        }
    }
    var landmarkAsset: String {
        switch self {
        case .moonwake: "MoonwakeMoon"
        case .nebula: "NebulaBankLeft"
        case .ringdrift: "RingdriftPlanet"
        case .garden: "GardenCanopy"
        case .shatterlight: "ShatterlightCrown"
        }
    }
}
