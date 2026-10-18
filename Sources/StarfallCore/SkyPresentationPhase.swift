/// Committed intermediate board snapshots, shared by collapse and historical orbit presentation.
public struct SkyPresentationPhase: Sendable {
    public enum Event: String, Sendable { case removal, collision, settling, capture, rotation, release }
    public let event: Event
    public let board: [StarfallGem?]
    public let field: OrbitField?
}
/// Compatibility for retained tools and histories; current code uses the neutral name.
public typealias GravityPhase = SkyPresentationPhase
