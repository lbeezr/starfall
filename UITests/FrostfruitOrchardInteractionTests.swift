import XCTest

final class FrostfruitOrchardInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .frostfruit }

    @MainActor func testFrostfruitWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero()
    }

    @MainActor func testFrostfruitDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero()
    }

    @MainActor func testFrostfruitLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable()
    }

    @MainActor func testFrostfruitPreviewCancellationRetainsLanternAndRibbonUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon])
    }

    @MainActor func testFrostfruitPreviewCancellationRetainsKiteAndSeedUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.kite, .seed])
    }

    @MainActor func testFrostfruitPreviewCancellationRetainsSilverUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.silver])
    }

    @MainActor func testFrostfruitPhoneAllFiveStatesKeepNativeBoardFixed() {
        exercisePhoneAllFiveStatesKeepNativeBoardFixed()
    }

    @MainActor func testFrostfruitDenseRapidClearSurvivesSettingsAndBackground() {
        exerciseDenseRapidClearSurvivesSettingsAndBackground()
    }

    @MainActor func testTabletRotationKeepsFrostfruitRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }

    @MainActor func testTabletDenseFrostfruitCompletionKeepsNativeInput() throws {
        try exerciseTabletDenseCompletionKeepsNativeInput()
    }
}
