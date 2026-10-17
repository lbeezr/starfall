import Foundation

/// An uncommitted choice. Browsing Entry never constructs or saves a replacement game.
enum SkyEntryRequest: Equatable, CaseIterable {
    case initial, fresh, replay, firstLight

    func isChallenge(replayingChallenge: Bool) -> Bool {
        self == .firstLight || (self == .replay && replayingChallenge)
    }
}

enum SkyFlowEffect: Equatable {
    case staged, began(SkyEntryRequest), continued, home, preferences
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
    private var generation: UInt64 = 0

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        screen = SkyFlowScreen.initial(arguments: arguments)
    }

    mutating func handle(_ action: SkyFlowAction, hasSavedSky: Bool, entryID expectedID: UInt64? = nil) -> SkyFlowEffect? {
        guard handoff == nil || action == .home else { return nil }
        switch action {
        case .preferences:
            guard screen == .welcome || screen == .entry else { return nil }
            return .preferences
        case .start:
            guard screen == .welcome else { return nil }
            return stage(hasSavedSky ? .fresh : .initial)
        case .firstLight:
            guard screen != .entry else { return nil }
            return stage(.firstLight)
        case .replay, .another:
            guard screen == .playing || screen == .won || screen == .full else { return nil }
            return stage(action == .replay ? .replay : .fresh)
        case .begin:
            guard screen == .entry, let request = entry, let entryID, expectedID == entryID else { return nil }
            entry = nil; self.entryID = nil
            beginHandoff(from: .entry, startsClock: true)
            return .began(request)
        case .resume:
            guard screen == .welcome, hasSavedSky else { return nil }
            beginHandoff(from: .welcome, startsClock: false)
            return .continued
        case .home:
            guard screen != .welcome else { return nil }
            entry = nil; entryID = nil; handoff = nil; screen = .welcome
            return .home
        }
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

    private mutating func stage(_ request: SkyEntryRequest) -> SkyFlowEffect {
        generation &+= 1; entryID = generation
        entry = request; screen = .entry
        return .staged
    }
}
