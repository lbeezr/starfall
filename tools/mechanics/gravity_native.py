"""Native shell for the gravity candidate; all edits are strict and export-local."""
from pathlib import Path
from gravity_candidate import replace_once
HERE=Path(__file__).resolve().parent

def apply_native(workspace):
    def edit(name, old, new):
        path=workspace/name; path.write_text(replace_once(path.read_text(),old,new))
    def append(name, fragment):
        path=workspace/name; path.write_text(path.read_text()+'\n'+(HERE/fragment).read_text())
    bundle='com.starfall.gravity.lab'
    suite='starfall.gravity.lab.v1'
    edit('Config/Clean.xcconfig','PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype',
         'PRODUCT_BUNDLE_IDENTIFIER = '+bundle+'\nINFOPLIST_KEY_CFBundleDisplayName = Gravity Lab')
    project=workspace/'Starfall.xcodeproj/project.pbxproj'
    project.write_text(project.read_text().replace('com.starfall.prototype.',bundle+'.'))
    edit('App/FallingSkyStore.swift','defaults: UserDefaults = .standard',
         'defaults: UserDefaults = UserDefaults(suiteName: "'+suite+'")!')
    edit('App/FallingSkyStore.swift','static let saveKey = SkySaveArchive.key', 'static let saveKey = "'+suite+'"')
    edit('App/FallingSkyStore.swift','SkySaveArchive.load(from: defaults)',
         'defaults.data(forKey: Self.saveKey).flatMap { GravitySave.restore($0) }')
    edit('App/FallingSkyStore.swift','SkySaveArchive.encode(game)','JSONEncoder().encode(GravitySave(game))')
    edit('App/FallingSkyStore.swift','        remaining = showerInterval\n        scene.onLayout', '''        if let name = arguments.first(where: { $0.hasPrefix("--gravity-fixture=") }),
           let fixture = GravityFixture(rawValue: String(name.dropFirst("--gravity-fixture=".count))) {
            game = fixture.game(); message = fixture.message
        }
        refreshCadence()
        remaining = showerInterval
        scene.onLayout''')
    edit('App/FallingSkyStore.swift','    func startFirstLight() {', '''    func loadGravityFixture(_ fixture: GravityFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock(); settlePresentation()
        game = fixture.game(); refreshCadence(); remaining = showerInterval
        message = fixture.message
        save(); presenter.render(game)
    }

    func startFirstLight() {''')
    edit('App/FallingSkyStore.swift','        // One settled, generation-guarded announcement owns both pressure axes.', '''        if !game.isOver, let field = game.orbit {
            message = "Orbit: \\(field.windowsRemaining) windows left. Clear a captive to release the others."
        } else if !game.isOver, turn.gravityPhases.contains(where: { $0.event == .release }) {
            message = "The hole closed. Its stars are free."
        }
        // One settled, generation-guarded announcement owns both pressure axes.''')
    edit('App/FallingSkyStore.swift','        guard let turn = game.clear(cell) else {', '''        guard let turn = game.clear(cell) else {
            if game.gem(at: cell)?.gravityKind != nil {
                message = game.gem(at: cell)?.gravityKind == .hole
                    ? "Clear a matching group containing a captive to close the hole."
                    : "Clear beside a magnet to dissolve it, or clear between a pair to form a hole."
                feedback.announce(message); return
            }''')
    edit('App/FallingSkyMenu.swift','    let done: () -> Void', '    let done: () -> Void\n    let gravityFixture: (GravityFixture) -> Void')
    edit('App/FallingSkyMenu.swift','                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)', '''                Section("Gravity examples") {
                    Text("Magnetic pairs collide when a clear opens their middle. A hole holds nearby stars for three windows. Each shower rotates them; clearing a captive releases them.")
                    ForEach(GravityFixture.allCases, id: \\.self) { fixture in
                        Button(fixture.title) { gravityFixture(fixture) }
                            .accessibilityIdentifier("gravity.fixture.\\(fixture.rawValue)")
                    }
                }
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)''')
    edit('App/FallingSkyView.swift','setBalance: store.setBalance, done: { menu = nil })',
         'setBalance: store.setBalance, done: { menu = nil },\n                       gravityFixture: { fixture in cancelConstellation(); store.loadGravityFixture(fixture); menu = nil })')
    edit('App/FallingSkyView.swift','        let shade = store.game.isGrowthBlocked(at: cell)', '''        if let role = gem.gravityKind {
            return role == .hole ? "Gravity hole, \\(store.game.orbit?.windowsRemaining ?? 0) windows left, \\(position)" : "Magnetic star, \\(position)"
        }
        let shade = store.game.isGrowthBlocked(at: cell)''')
    edit('App/FallingSkyView.swift','        return "\\(gem.grown ? "Large " : "")', '''        let captive = store.game.orbit?.slots.contains(cell) == true ? "Captive, " : ""
        return "\\(captive)\\(gem.grown ? "Large " : "")''')
    edit('App/FallingSkyView.swift','.accessibilityHint(store.game.gem(at: cell)?.isDark == true', '''.accessibilityHint(store.game.gem(at: cell)?.gravityKind == .hole
            ? "Clear a matching group containing a captive to close this hole"
            : store.game.gem(at: cell)?.gravityKind == .magnet
            ? "Clear beside it to dissolve it. Clear between a pair to form a hole"
            : store.game.orbit?.slots.contains(cell) == true
            ? "A legal clear containing this captive closes the hole and releases the others"
            : store.game.gem(at: cell)?.isDark == true''')
    # The same Core preview used by fixtures describes actual collision selection, not animation guesses.
    edit('App/FallingSkyView.swift','.accessibilityIdentifier("experiment.cell.\\(cell.row).\\(cell.column)")',
         '.accessibilityCustomContent("Gravity consequence", gravityConsequence(cell))\n        .accessibilityIdentifier("experiment.cell.\\(cell.row).\\(cell.column)")')
    edit('App/FallingSkyView.swift','    private func cellLabel(_ cell: Cell) -> String {', '''    private func gravityConsequence(_ cell: Cell) -> String {
        guard let preview = store.game.gravityPreview(at: cell), let field = preview.orbit,
              store.game.orbit == nil else { return "No new hole" }
        return "Forms a hole at row \\(7-field.center.row), column \\(field.center.column+1), holding \\(field.slots.count) stars"
    }

    private func cellLabel(_ cell: Cell) -> String {''')
    edit('App/FallingSkyScene.swift','        FallingSkyCharacter(gem: gem, step: step)', '''        let node = FallingSkyCharacter(gem: gem, step: step)
        GravityMaterial.decorate(node, gem: gem, step: step)
        return node''')
    edit('App/FallingSkyScene.swift','        let matchable = Set(game.legalGroups.flatMap { $0 })',
         '        renderGravityField(game.orbit)\n        let matchable = Set(game.legalGroups.flatMap { $0 })')
    edit('App/FallingSkyScene.swift','        render(old)\n        rendered = game', '''        if !turn.gravityPhases.isEmpty {
            animateGravity(turn, from: old, to: game, completion: completion); return
        }
        render(old)
        rendered = game''')
    append('App/FallingSkyScene.swift','GravityScene.swift')
    append('AppTests/FallingSkyStoreTests.swift','GravityStoreTests.swift')
    append('UITests/FallingSkyInteractionTests.swift','GravityUITests.swift')
    append('AppTests/FallingSkyStoreTests.swift','GravityTraceStoreTests.swift')
    append('UITests/FallingSkyInteractionTests.swift','GravityTraceUITests.swift')
