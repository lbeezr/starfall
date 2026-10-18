import XCTest
import StarfallCore
@testable import Starfall

final class SkyCadenceCueTests: XCTestCase {
    func testBaselineAndOpeningHaveNoCue() {
        for count in 0...30 {
            XCTAssertNil(SkyCadenceCueCopy(step: SkyCadenceID.openingV1.step(committedShowers: count, pace: .brisk)))
            XCTAssertNil(SkyCadenceCueCopy(step: SkyCadenceID.originalV1.step(committedShowers: count, pace: .steady)))
        }
    }

    func testCanonicalCandidateBoundariesExposeExactWarningAndNoSafetyPromise() {
        let warning = SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: 9))
        XCTAssertEqual(warning?.title, "Showers get faster after the next shower.")
        XCTAssertEqual(warning?.label, "Showers get faster after the next shower.")
        for count in 10...12 {
            XCTAssertEqual(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: count))?.label,
                           "Showers are closer together now.")
        }
        for count in 13...15 {
            XCTAssertEqual(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: count))?.label,
                           "More time between showers now.")
        }
        XCTAssertNil(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: 16)))
        XCTAssertNil(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: 9, pace: .gentle)))
    }
}
