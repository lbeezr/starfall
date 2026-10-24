"""Source-counted native matrices; actual VoiceOver sessions belong to RC."""
import argparse
import json
from pathlib import Path
import re

VOICEOVER_RC = {
    'FallingSkyInteractionTests': {'testVoiceOverReadsPausedGrowthFeedback'},
    'ObservatoryInteractionTests': {
        'testVoiceOverSpeechActivationPropsClearAndMenuFocus',
        'testVoiceOverLargestTextOverflowAndReplay',
        'testVoiceOverAutomaticRainMenuAndBackground',
        'testVoiceOverFullFirstLightRoundRestoreAndReplay',
        'testVoiceOverOpalIdentityActivationAndStormCue'},
}
TABLET_ONLY = {
    'testLargestCalmHeadroomAndFullBoardRefillReadCompletely': 'StarfallUITests/HeadroomFeedbackInteractionTests/testLargestCalmHeadroomAndFullBoardRefillReadCompletely',
    'testLargestCalmShowerInspectionReadsWithoutCommitAndFullBoardHasNone': 'StarfallUITests/ShowerInspectionInteractionTests/testLargestCalmShowerInspectionReadsWithoutCommitAndFullBoardHasNone',
    'testLargestCalmLanternForecastFocusRetiresBeforeFullBoard': 'StarfallUITests/ForecastColumnInspectionInteractionTests/testLargestCalmLanternForecastFocusRetiresBeforeFullBoard',
    'testLargestCalmRibbonSetupDiagramsDoNotPlayForYou': 'StarfallUITests/FullBoardChoiceDiagramInteractionTests/testLargestCalmRibbonSetupDiagramsDoNotPlayForYou',
    'testLargestCalmFullBoardIngredientsInspectThenClear': 'StarfallUITests/StoryIngredientInspectionInteractionTests/testLargestCalmFullBoardIngredientsInspectThenClear',
    'testLargestCalmModeGuidanceCancellationAndExactContinue': 'StarfallUITests/IdentityJourneyInteractionTests/testLargestCalmModeGuidanceCancellationAndExactContinue',
    'testLargestCalmPracticeFinalLightRetryAndRetainedRound': 'StarfallUITests/FinalLightInteractionTests/testLargestCalmPracticeFinalLightRetryAndRetainedRound',
    'testLargestCalmFullBoardWinFinalLightAndExactReplay': 'StarfallUITests/FinalLightInteractionTests/testLargestCalmFullBoardWinFinalLightAndExactReplay',
    'testLargestCalmSameAwardPortraitLandscapeAndExactReplay': 'StarfallUITests/RibbonAwardResponseInteractionTests/testLargestCalmSameAwardPortraitLandscapeAndExactReplay',
    'testLargestCalmBelowMilestoneMilestoneAndFinalRepairKeepExactReplay': 'StarfallUITests/LanternAwardResponseInteractionTests/testLargestCalmBelowMilestoneMilestoneAndFinalRepairKeepExactReplay',
    'testLargestCalmDenseChainAndSimultaneousPatternsKeepRetainedRound': 'StarfallUITests/CascadeReturnInteractionTests/testLargestCalmDenseChainAndSimultaneousPatternsKeepRetainedRound',
    'testLargestCalmFullBoardAndPairedPatternPracticeKeepRetainedRound': 'StarfallUITests/AutomaticPatternReturnInteractionTests/testLargestCalmFullBoardAndPairedPatternPracticeKeepRetainedRound',
    'testTabletLargestTextCalmTraceKeepsHintOptionalAndRoundSafe': 'StarfallUITests/OpenSkyPracticeInteractionTests/testTabletLargestTextCalmTraceKeepsHintOptionalAndRoundSafe',
    'testLandscapeWelcomeEntryAndPreferences': 'StarfallUITests/SkyFlowInteractionTests/testLandscapeWelcomeEntryAndPreferences',
    'testTabletRotationKeepsRestorationAndNativeInput': 'StarfallUITests/LanternLandingInteractionTests/testTabletRotationKeepsRestorationAndNativeInput',
    'testTabletRotationKeepsRibbonRestorationAndNativeInput': 'StarfallUITests/RibbonCrossingInteractionTests/testTabletRotationKeepsRibbonRestorationAndNativeInput',
    'testTabletRotationKeepsKiteRestorationAndNativeInput': 'StarfallUITests/KiteHarborInteractionTests/testTabletRotationKeepsKiteRestorationAndNativeInput',
    'testTabletRotationKeepsSeedRestorationAndNativeInput': 'StarfallUITests/SeedMoonInteractionTests/testTabletRotationKeepsSeedRestorationAndNativeInput',
    'testTabletRotationKeepsSilverRestorationAndNativeInput': 'StarfallUITests/SilverPoolsInteractionTests/testTabletRotationKeepsSilverRestorationAndNativeInput',
    'testTabletDenseSilverCompletionKeepsNativeInput': 'StarfallUITests/SilverPoolsInteractionTests/testTabletDenseSilverCompletionKeepsNativeInput',
    'testTabletRotationKeepsFrostfruitRestorationAndNativeInput': 'StarfallUITests/FrostfruitOrchardInteractionTests/testTabletRotationKeepsFrostfruitRestorationAndNativeInput',
    'testTabletDenseFrostfruitCompletionKeepsNativeInput': 'StarfallUITests/FrostfruitOrchardInteractionTests/testTabletDenseFrostfruitCompletionKeepsNativeInput',
    'testTabletRotationKeepsSunwheelRestorationAndNativeInput': 'StarfallUITests/SunwheelMillInteractionTests/testTabletRotationKeepsSunwheelRestorationAndNativeInput',
    'testTabletDenseSunwheelCompletionKeepsNativeInput': 'StarfallUITests/SunwheelMillInteractionTests/testTabletDenseSunwheelCompletionKeepsNativeInput',
}
METHOD = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*func\s+(test\w+)\s*\(\s*\)', re.MULTILINE)


def plan(root, stage):
    if stage not in ('dev', 'rc'):
        raise ValueError('Native acceptance stage must be dev or rc')
    expectations = {}; deferred = []
    for target, directory in [('StarfallUITests', 'UITests'), ('StarfallAppTests', 'AppTests')]:
        sources = {}
        for path in sorted((root / directory).rglob('*.swift')):
            names = METHOD.findall(path.read_text())
            if target == 'StarfallUITests':
                names = [name for name in names if name not in TABLET_ONLY]
            if target == 'StarfallUITests' and stage == 'dev':
                deferred.extend(f'{target}/{path.stem}/{name}' for name in names if name in VOICEOVER_RC.get(path.stem, set()))
                names = [name for name in names if name not in VOICEOVER_RC.get(path.stem, set())]
            if names:
                sources[str(path.relative_to(root))] = names
        count = sum(map(len, sources.values()))
        if not count:
            raise ValueError('Refusing an empty native matrix: ' + target)
        expectations[target] = {'expectedCount': count, 'testMethodsBySource': sources}
    return expectations, deferred


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', choices=['dev', 'rc'], default='dev')
    args = parser.parse_args()
    result, deferred = plan(Path.cwd(), args.stage)
    Path('artifacts').mkdir(exist_ok=True)
    Path('artifacts/native-test-expectations.json').write_text(json.dumps(result, indent=2) + '\n')
    Path('artifacts/native-test-matrix.json').write_text(json.dumps({'stage': args.stage, 'deferredToRC': deferred, 'tabletOnly': list(TABLET_ONLY.values())}, indent=2) + '\n')
    Path('artifacts/native-test-exclusions.txt').write_text(''.join(name + '\n' for name in deferred + list(TABLET_ONLY.values())))
    print('Native ' + args.stage + ' matrix: ' + ', '.join(f'{key}={value["expectedCount"]}' for key, value in result.items()))
