// Appended within the exported scene file; uses its authoritative shared projection.
private extension FallingSkyScene {
    func renderConstellationLinks(_ game: FallingSky) {
        for group in game.legalGroups where group.count >= 5 {
            var reached: Set<Cell> = [group[0]], pending = [group[0]]
            while let cell = pending.popLast() {
                for next in group where !reached.contains(next)
                    && abs(next.row-cell.row) <= 1 && abs(next.column-cell.column) <= 1 {
                    reached.insert(next); pending.append(next)
                    let a = point(cell), b = point(next)
                    let path = CGMutablePath()
                    path.move(to: a); path.addLine(to: b)
                    let link = SKShapeNode(path: path)
                    link.name = "lab.constellation.link"
                    link.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(0.5)
                    link.lineWidth = 1.2; link.glowWidth = 1
                    grid.addChild(link)
                }
            }
        }
    }
}
