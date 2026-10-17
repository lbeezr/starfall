@MainActor private func clearCanonicalBurstGroup(in app: XCUIApplication) {
    let legal = app.buttons.matching(NSPredicate(format: "value MATCHES %@",
        "([3-9]|[1-9][0-9]+) starlight connected")).allElementsBoundByIndex
    let canonical = legal.sorted {
        let lhs = $0.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
        let rhs = $1.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
        return lhs.lexicographicallyPrecedes(rhs)
    }.first
    canonical?.tap()
}
