import Foundation
import StarfallCore

/// An uncommitted choice. Browsing Entry never constructs or saves a replacement game.
enum SkyEntryRequest: Hashable, CaseIterable {
    case initial, fresh, replay, firstLight, fullBoardLantern, ribbonCrossing, kiteHarbor, seedMoon, silverPools, frostfruitOrchard, sunwheelMill

    func selectedChallenge(replaying challenge: StarfallChallenge?) -> StarfallChallenge? {
        switch self {
        case .firstLight, .fullBoardLantern: .firstLight
        case .ribbonCrossing: .ribbonCrossing
        case .kiteHarbor: .kiteHarbor
        case .seedMoon: .seedMoon
        case .silverPools: .silverPools
        case .frostfruitOrchard: .frostfruitOrchard
        case .sunwheelMill: .sunwheelMill
        case .replay: challenge
        case .initial, .fresh: nil
        }
    }
}

enum SkyFlowEffect: Equatable {
    case staged, began(SkyEntryRequest), continued, home, preferences, worldMap, tutorial
}

struct SkyPlayHandoff: Equatable {
    let id: UInt64
    let source: SkyFlowScreen
    let startsClock: Bool
    var settled = false
    var preparing = false
}

/// Presentation-only admission: duplicate or stale actions cannot begin another round.
struct SkyFlowState: Equatable {
    private(set) var screen: SkyFlowScreen
    private(set) var entry: SkyEntryRequest?
    private(set) var entryID: UInt64?
    private(set) var handoff: SkyPlayHandoff?
    private var mapOrigin: SkyFlowScreen?
    private var entryOrigin: SkyFlowScreen?
    private var generation: UInt64 = 0

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        screen = SkyFlowScreen.initial(arguments: arguments)
    }

    init(practice: SkyTutorial) { screen = .playing }

    mutating func handle(_ action: SkyFlowAction, hasSavedSky: Bool, entryID expectedID: UInt64? = nil) -> SkyFlowEffect? {
        guard handoff == nil || action == .home else { return nil }
        switch action {
        case .onward:
            // Requires the committed result and selection write in openOnward.
            return nil
        case .worldMap:
            guard screen != .worldMap, screen != .entry else { return nil }
            mapOrigin = screen; screen = .worldMap
            return .worldMap
        case .worldBack:
            guard screen == .worldMap else { return nil }
            screen = mapOrigin ?? .welcome; mapOrigin = nil
            return screen == .playing ? .continued : .home
        case .tutorial: return .tutorial
        case .preferences:
            guard screen == .welcome || screen == .entry else { return nil }
            return .preferences
        case .start:
            guard screen == .welcome else { return nil }
            return stage(hasSavedSky ? .fresh : .initial)
        case .firstLight: return stageLantern(.firstLight, expectedID: expectedID)
        case .fullBoardLantern: return stageLantern(.fullBoardLantern, expectedID: expectedID)
        case .ribbonCrossing: return stageChallenge(.ribbonCrossing)
        case .kiteHarbor: return stageChallenge(.kiteHarbor)
        case .seedMoon: return stageChallenge(.seedMoon)
        case .silverPools: return stageChallenge(.silverPools)
        case .frostfruitOrchard: return stageChallenge(.frostfruitOrchard)
        case .sunwheelMill: return stageChallenge(.sunwheelMill)
        case .replay, .another:
            guard screen == .playing || screen == .won || screen == .full else { return nil }
            return stage(action == .replay ? .replay : .fresh)
        case .begin:
            guard screen == .entry, let request = entry, let entryID, expectedID == entryID else { return nil }
            entry = nil; self.entryID = nil; entryOrigin = nil; mapOrigin = nil
            beginHandoff(from: .entry, startsClock: true)
            return .began(request)
        case .entryBack:
            guard screen == .entry, let entryID, expectedID == entryID else { return nil }
            screen = entryOrigin ?? .welcome
            entry = nil; self.entryID = nil; entryOrigin = nil
            return screen == .worldMap ? .worldMap : .home
        case .resume:
            guard screen == .welcome || screen == .worldMap, hasSavedSky else { return nil }
            let source = screen; mapOrigin = nil
            beginHandoff(from: source, startsClock: false)
            return .continued
        case .home:
            guard screen != .welcome else { return nil }
            entry = nil; entryID = nil; entryOrigin = nil; handoff = nil; mapOrigin = nil; screen = .welcome
            return .home
        }
    }

    /// Revalidate the result when invoked. A failed selection cannot publish navigation.
    mutating func openOnward(_ destination: WorldLocation, game: FallingSky, journey: WorldJourney,
                             hasSavedSky: Bool, terminalReady: Bool, active: Bool, modal: Bool,
                             select: (WorldLocation) throws -> Void) rethrows -> Bool {
        guard active, !modal, terminalReady, hasSavedSky,
              screen == .playing || screen == .won,
              SkyOnwardSnapshot(game: game, journey: journey)?.destination == destination else { return false }
        var next = self
        guard next.handle(.worldMap, hasSavedSky: hasSavedSky) == .worldMap else { return false }
        try select(destination)
        self = next
        return true
    }

    mutating func settleHandoff(_ id: UInt64) {
        guard handoff?.id == id else { return }
        handoff?.settled = true
    }

    mutating func showPreparation(_ id: UInt64) {
        guard handoff?.id == id else { return }
        handoff?.preparing = true
    }

    /// Readiness admits presentation only. It never chooses a core outcome or cadence.
    mutating func completeHandoff(_ id: UInt64, ready: Bool, active: Bool, modal: Bool) -> Bool? {
        guard let handoff, handoff.id == id, handoff.settled, ready, active, !modal else { return nil }
        self.handoff = nil
        return handoff.startsClock
    }

    private mutating func beginHandoff(from source: SkyFlowScreen, startsClock: Bool) {
        generation &+= 1
        handoff = SkyPlayHandoff(id: generation, source: source, startsClock: startsClock)
        screen = .playing
    }

    private mutating func stageChallenge(_ request: SkyEntryRequest) -> SkyFlowEffect? {
        guard screen != .entry else { return nil }
        return stage(request)
    }

    /// Only the visible Lantern comparison may revise an already staged visit.
    /// A revision invalidates old Begin callbacks while retaining the map origin.
    private mutating func stageLantern(_ request: SkyEntryRequest, expectedID: UInt64?) -> SkyFlowEffect? {
        guard screen == .entry else { return stage(request) }
        guard entry == .firstLight || entry == .fullBoardLantern,
              entry != request, expectedID == entryID else { return nil }
        generation &+= 1; entryID = generation
        entry = request
        return .staged
    }

    private mutating func stage(_ request: SkyEntryRequest) -> SkyFlowEffect {
        // A destination inspection returns to its map; that map still owns its
        // original Home/play destination. Direct new/replay choices cancel Home.
        entryOrigin = screen == .worldMap ? .worldMap : .welcome
        if screen != .worldMap { mapOrigin = nil }
        generation &+= 1; entryID = generation
        entry = request; screen = .entry
        return .staged
    }
}
