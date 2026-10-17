"""Single owner for the isolated diagonal rule; never patches shipping source."""
def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError(f"Core contract changed: {old[:80]}")
    return text.replace(old, new)

def candidate_source(text: str, *, analysis: bool = False) -> str:
    text = replace_once(text, '    public var legalGroups: [[Cell]] {', '    public var orthogonalLegalGroups: [[Cell]] {')
    text = replace_once(text, '    public func group(at start: Cell) -> Set<Cell> {', '    public func orthogonalGroup(at start: Cell) -> Set<Cell> {')
    text = replace_once(text, 'let group = group(at: cell); seen.formUnion(group)', 'let group = orthogonalGroup(at: cell); seen.formUnion(group)')
    text = replace_once(text, 'turns > 0 && legalGroups.isEmpty', 'turns > 0 && orthogonalLegalGroups.isEmpty')
    start = text.index('    @discardableResult public mutating func clear(')
    end = text.index('    /// Clock-independent event:', start)
    ordinary_clear = text[start:end].replace('func clear(', 'func clearOrdinaryForComparison(').replace('let cells = group(at: cell)', 'let cells = orthogonalGroup(at: cell)')
    addition = '''
        // Isolated trial: whole constellation takes precedence; dark effects stay orthogonal.
        public func group(at start: Cell) -> Set<Cell> {
            guard let kind = gem(at: start)?.kind else { return [] }
            var found: Set<Cell> = [start], pending = [start]
            while let cell = pending.popLast() {
                for dr in -1...1 { for dc in -1...1 where dr != 0 || dc != 0 {
                    let next = Cell(cell.row + dr, cell.column + dc)
                    if !found.contains(next), gem(at: next)?.kind == kind {
                        found.insert(next); pending.append(next)
                    }
                } }
            }
            return found.count >= 5 ? found : orthogonalGroup(at: start)
        }

        public var legalGroups: [[Cell]] {
            var seen: Set<Cell> = [], result: [[Cell]] = []
            for row in 0..<Self.side { for column in 0..<Self.side {
                let cell = Cell(row, column)
                guard !seen.contains(cell) else { continue }
                let cells = group(at: cell)
                seen.formUnion(cells)
                if value(of: cells) >= 3 {
                    result.append(cells.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row })
                }
            } }
            return result
        }
    '''
    text = replace_once(text, '    public var isValidSave: Bool {', addition + (ordinary_clear if analysis else '') + '\n    public var isValidSave: Bool {')
    return text
