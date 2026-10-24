import StarfallCore

/// Retrospective wording shares the committed recap value; it cannot forecast
/// or change the current round after another action has taken place.
enum SkyLastClearCopy {
    static func context(_ context: SkyLastClearSnapshot.Context) -> String {
        guard let challenge = context.challenge else { return SkyCopy.text(.flowOpen) }
        return SkyCopy.text(.lastClearContext, values: ["place": challenge.locationTitle,
            "mode": SkyCopy.text(context.fullBoard ? .fullBoardMode : .fallingSkyMode)])
    }

    static func phaseTitle(_ number: Int) -> String {
        SkyCopy.text(.lastClearPhase, values: ["number": String(number)])
    }

    static func ingredients(_ phase: SkyLastClearSnapshot.Phase) -> String {
        let positions = phase.cleared.sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row > $1.row
        }.map { cell in
            let position = SkyCopy.boardPosition(cell)
            let text = SkyCopy.position(row: position.row, column: position.column)
            return phase.drained.contains(cell)
                ? SkyCopy.text(.lastClearGrayPosition, values: ["position": text]) : text
        }.joined(separator: "; ")
        let base = SkyCopy.text(.lastClearIngredients, values: ["positions": positions])
        return phase.drained.isEmpty ? base : base + " " + SkyCopy.text(.lastClearDrained)
    }

    static func room(_ snapshot: SkyLastClearSnapshot) -> String? {
        var facts: [String] = []
        if snapshot.context.fullBoard {
            facts.append(refillText(snapshot.totalRefillCount))
        } else if case .opened(let columns, let spaces) = snapshot.headroom?.kind {
            let key: SkyCopy.Key = columns.count > 1 ? .headroomOpenedColumns
                : spaces == 1 ? .headroomOpenedCell : .headroomOpenedColumn
            var values = ["columns": columns.map { String($0 + 1) }.joined(separator: ", ")]
            if key != .headroomOpenedCell { values["count"] = String(spaces) }
            facts.append(SkyCopy.text(key, values: values))
        }
        facts.append(SkyCopy.text(.lastClearBoard, values: ["count": String(snapshot.resultingOccupiedCount)]))
        return facts.joined(separator: " ")
    }

    static func refills(_ phase: SkyLastClearSnapshot.Phase) -> String {
        refillText(phase.refillCount)
    }

    private static func refillText(_ count: Int) -> String {
        SkyCopy.text(count == 1 ? .lastClearRefillOne : .lastClearRefills,
                     values: count == 1 ? [:] : ["count": String(count)])
    }
}
