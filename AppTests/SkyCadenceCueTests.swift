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
        XCTAssertEqual(warning?.title, "Faster after next shower")
        XCTAssertEqual(warning?.label, "Faster after next shower")
        for count in 10...12 {
            XCTAssertEqual(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: count))?.label,
                           "Faster passage. Showers are closer together")
        }
        for count in 13...15 {
            XCTAssertEqual(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: count))?.label,
                           "Breathing window. More time between showers")
        }
        XCTAssertNil(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: 16)))
        XCTAssertNil(SkyCadenceCueCopy(step: TimingCycleFixture.step(committedShowers: 9, pace: .gentle)))
    }
}
