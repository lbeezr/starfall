import XCTest

final class SilverPoolsInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .silver }

    @MainActor func testSilverWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero()
    }

    @MainActor func testSilverDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero()
    }

    @MainActor func testSilverLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable()
    }

    @MainActor func testSilverPreviewCancellationRetainsLanternAndRibbonUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon])
    }

    @MainActor func testSilverPreviewCancellationRetainsKiteAndSeedUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.kite, .seed])
    }

    @MainActor func testSilverPhoneAllFiveStatesKeepNativeBoardFixed() {
        exercisePhoneAllFiveStatesKeepNativeBoardFixed()
    }

    @MainActor func testSilverDenseRapidClearSurvivesSettingsAndBackground() {
        exerciseDenseRapidClearSurvivesSettingsAndBackground()
    }

    @MainActor func testTabletRotationKeepsSilverRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }

    @MainActor func testTabletDenseSilverCompletionKeepsNativeInput() throws {
        try exerciseTabletDenseCompletionKeepsNativeInput()
    }
}
