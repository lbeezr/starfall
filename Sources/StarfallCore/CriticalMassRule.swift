import Foundation

/// Saved version 1: all collectible stars age, including buried stars and Opal.
public enum CriticalMassRule {
    public static let version = 1
    public static let showersPerStage = 3
    public static let collapseAge = showersPerStage * 3
}

/// A committed inward swallow, shared by universal pressure and retained Dusk presentation.
public struct StarCollapse: Equatable, Sendable {
    public let center: Cell
    public let sourceID: Int
    public let consumed: Set<Cell>
    public init(center: Cell, sourceID: Int, consumed: Set<Cell>) {
        self.center = center; self.sourceID = sourceID; self.consumed = consumed
    }
}
