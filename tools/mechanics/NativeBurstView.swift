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
            if remaining == 9 && phaseForecastNumber > 12 { return "Recovery · 9 calmer showers" }
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
                if voiceOver { UIAccessibility.post(notification: .announcement, argument: text) }
            }
    }
}
