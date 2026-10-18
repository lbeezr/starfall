/// Stable column compaction. Historical occupied anchors divide columns into segments.
public enum SkyBoardSettling {
    public static func height(_ board: [StarfallGem?], column: Int) -> Int {
        (0..<7).last(where: { board[$0*7+column] != nil }).map { $0+1 } ?? 0
    }
    public static func settle(_ board: [StarfallGem?], anchors: Set<Cell> = []) -> [StarfallGem?] {
        var result = board
        for column in 0..<7 {
            var base = 0
            let stops = (0..<7).filter { anchors.contains(Cell($0,column)) } + [7]
            for stop in stops {
                let survivors = (base..<stop).compactMap { board[$0*7+column] }
                for row in base..<stop { result[row*7+column] = row-base < survivors.count ? survivors[row-base] : nil }
                base = stop+1
            }
        }
        return result
    }
}
