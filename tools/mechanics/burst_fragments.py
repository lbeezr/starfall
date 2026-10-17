"""Shared labels and fragment expansion for frozen and current phase exports."""
from pathlib import Path


def burst_labels(bundle: str, surge: bool, preview_visible: bool) -> dict:
    return {
        "__LAB_BUNDLE__": bundle,
        "__BURST_WARNING__": "Five-star surge after this shower" if surge else "Pressure follows this shower",
        "__BURST_COUNT__": r'Surge · \(remaining) five-star \(remaining == 1 ? "shower" : "showers")' if surge else r'Pressure · \(remaining) \(remaining == 1 ? "shower" : "showers") remaining',
        "__BURST_THREE__": "Surge · 3 five-star showers" if surge else "Pressure · 3 showers remaining",
        "__BURST_PREVIEW_CHECK__": '''            if remaining > 0 {
                XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(
                    format: "identifier BEGINSWITH %@", "experiment.incoming.")).count, 5)
            }''' if surge and preview_visible else "",
        "__BURST_STORE_CHECK__": '''            if (9...11).contains(turn) { XCTAssertEqual(stores[0].game.incoming.count, 5) }
            if (10...12).contains(turn) { XCTAssertEqual(stores[0].pending?.forecast.count, 5) }''' if surge else "",
    }


def render_burst_fragment(path: Path, labels: dict) -> str:
    text = path.read_text()
    for token, value in labels.items():
        text = text.replace(token, value)
    if "__BURST_" in text or "__LAB_" in text:
        raise RuntimeError("Unresolved phase fragment token in " + path.name)
    return text
