final class BurstPhaseAnnouncementTests: XCTestCase {
    func testOnlyWarningEntryAndRecoveryRequestAutomaticSpeech() {
        let spoken = (1...25).filter {
            BurstPhaseAnnouncement.shouldAnnounce(forecastNumber: $0, isOver: false, isChallenge: false)
        }
        XCTAssertEqual(spoken, [9, 10, 13, 21, 22, 25],
            "Ordinary preparation and event countdown ticks remain readable without unsolicited speech")
        let fullCycle = (13...24).filter {
            BurstPhaseAnnouncement.shouldAnnounce(forecastNumber: $0, isOver: false, isChallenge: false)
        }
        XCTAssertEqual(fullCycle.count, 3)
    }

    func testChallengeAndEndedSkyLeaveOutcomeSpeechToTheStore() {
        for number in [9, 10, 13, 21, 22, 25] {
            XCTAssertFalse(BurstPhaseAnnouncement.shouldAnnounce(
                forecastNumber: number, isOver: true, isChallenge: false))
            XCTAssertFalse(BurstPhaseAnnouncement.shouldAnnounce(
                forecastNumber: number, isOver: false, isChallenge: true))
        }
        for number in [Int.min, -1, 0] {
            XCTAssertFalse(BurstPhaseAnnouncement.shouldAnnounce(
                forecastNumber: number, isOver: false, isChallenge: false))
        }
    }
}
