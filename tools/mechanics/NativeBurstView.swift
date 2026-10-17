/// Announcement cadence is presentation policy, separate from core shower rules.
/// Keep every count readable on focus, but reserve unsolicited speech for events.
enum BurstPhaseAnnouncement {
    static func shouldAnnounce(forecastNumber: Int, isOver: Bool, isChallenge: Bool) -> Bool {
        guard forecastNumber > 0, !isOver, !isChallenge else { return false }
        switch StarfallExperiment.showerPhase(for: forecastNumber) {
        case .preparation(let remaining):
            return remaining == 1 || (remaining == 9 && forecastNumber > 12)
        case .pressure(let remaining):
            return remaining == 3
        }
    }
}

extension StarfallExperimentView {
    // During rain presentation the visible forecast is the committed shower.
    // During clear presentation it remains the next shower. Mirror that owner.
    private var phaseForecastNumber: Int {
        store.pending?.arrivals.isEmpty == false ? store.game.turns : store.game.turns + 1
    }

    private var phaseText: String {
        if store.game.isOver { return "Sky ended" }
        if store.game.challenge != nil { return "First Light · no pressure phases" }
        switch StarfallExperiment.showerPhase(for: phaseForecastNumber) {
        case .preparation(let remaining):
            if remaining == 1 { return "__BURST_WARNING__" }
            if phaseForecastNumber > 12 { return "Recovery · \(remaining) calmer showers" }
            return "Prepare · \(remaining) calmer showers"
        case .pressure(let remaining):
            return "__BURST_COUNT__"
        }
    }

    private var phaseCue: some View {
        Label(phaseText, systemImage: "waveform.path")
            .font(StarfallTheme.Typography.gameDetail)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("lab.phase")
            .onChange(of: phaseText) { _, text in
                if voiceOver, BurstPhaseAnnouncement.shouldAnnounce(
                    forecastNumber: phaseForecastNumber, isOver: store.game.isOver,
                    isChallenge: store.game.challenge != nil) {
                    UIAccessibility.post(notification: .announcement, argument: text)
                }
            }
    }
}
