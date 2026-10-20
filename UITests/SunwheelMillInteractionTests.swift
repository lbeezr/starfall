import XCTest

final class SunwheelMillInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .sunwheel }

    @MainActor func testSunwheelWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero()
    }

    @MainActor func testSunwheelDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero()
    }

    @MainActor func testSunwheelLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable()
    }

    @MainActor func testSunwheelPreviewCancellationRetainsLanternAndRibbonUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon])
    }

    @MainActor func testSunwheelPreviewCancellationRetainsKiteAndSeedUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.kite, .seed])
    }

    @MainActor func testSunwheelPreviewCancellationRetainsSilverAndFrostfruitUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.silver, .frostfruit])
    }

    @MainActor func testSunwheelPhoneAllFiveStatesKeepNativeBoardFixed() {
        exercisePhoneAllFiveStatesKeepNativeBoardFixed()
    }

    @MainActor func testSunwheelDenseRapidClearSurvivesSettingsAndBackground() {
        exerciseDenseRapidClearSurvivesSettingsAndBackground()
    }

    @MainActor func testTabletRotationKeepsSunwheelRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }

    @MainActor func testTabletDenseSunwheelCompletionKeepsNativeInput() throws {
        try exerciseTabletDenseCompletionKeepsNativeInput()
    }
}
