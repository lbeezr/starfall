import Foundation

/// Shared storage selection for committed skies and SwiftUI preferences.
/// Reading this boundary never resets a domain or writes defaults.
enum SkyDefaults {
    static func forApp(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        #if DEBUG
        for (flag, suite) in [("--technique-review", "Starfall.TechniqueReview"),
                              ("--dialogue-review", "Starfall.DialogueReview"),
                              ("--sky-flow-review", "Starfall.SkyFlowReview")] {
            if arguments.contains(flag) { return UserDefaults(suiteName: suite)! }
        }
        if arguments.contains("--starfalls-reset"), arguments.contains("--observatory-review") {
            return UserDefaults(suiteName: "Starfall.ObservatoryReview")!
        }
        #endif
        return .standard
    }
}
