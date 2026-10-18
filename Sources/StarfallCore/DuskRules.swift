import Foundation

/// A compatibility contract, not a player-selectable mode. New app skies adopt feeding.
public enum DuskRule: Int, Codable, Sendable { case legacy = 0, feeding = 1
    public static let feedingShowers = 3
}

public struct DuskCollapse: Equatable, Sendable {
    public let center: Cell
    public let duskID: Int
    public let consumed: Set<Cell>
}
