"""Stamp one stable development app identity with a reproducible runtime fingerprint."""
from pathlib import Path
import plistlib
from constellation_candidate import replace_once


def stamp_lab(workspace: Path) -> str:
    config = workspace/'Config/Clean.xcconfig'
    config.write_text(replace_once(config.read_text(), 'CURRENT_PROJECT_VERSION = 1', 'CURRENT_PROJECT_VERSION = 2')
                      .replace('INFOPLIST_KEY_CFBundleDisplayName = Constellation Lab', 'INFOPLIST_KEY_CFBundleDisplayName = Starfall Lab'))
    menu = workspace/'App/FallingSkyMenu.swift'
    text = menu.read_text().replace('.navigationTitle("Constellation Lab")', '.navigationTitle("Starfall Lab")')
    text = text.replace('Section("Constellation Lab")', 'Section("Try a constellation")')
    text = replace_once(text, '                    Text("Separate comparison app. These examples replace only this lab sky.")', '''                    Text("These examples replace only this lab sky.")
                    Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "Development build")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("lab.buildID")''')
    menu.write_text(text)
    (workspace/'Config/Lab-Info.plist').write_bytes(plistlib.dumps({'StarfallBuildID': '$(STARFALL_BUILD_ID)'}))
    with config.open('a') as output: output.write('\nINFOPLIST_FILE = Config/Lab-Info.plist\n')
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
    from build_identity import build_id as runtime_build_id
    build_id = runtime_build_id(workspace)
    with config.open('a') as output: output.write('\nSTARFALL_BUILD_ID = '+build_id+'\n')
    return build_id
