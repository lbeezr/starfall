import XCTest
@testable import Starfall

final class SkyDialogueCatalogBoundsTests: XCTestCase {
    private func catalog(copy: [String: String]) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "schemaVersion": 1,
            "scripts": [["id": "test", "lines": [["id": "test.1", "speaker": "sunny",
                                                      "text": "Hello", "priority": "help"]]]],
            "copy": copy
        ])
    }

    func testBoundedCatalogueAdmitsTheExpandedInventoryAtItsCapacity() throws {
        let copy = Dictionary(uniqueKeysWithValues: (0..<1_024).map { ("copy.\($0)", "A local label") })
        let decoded = try SkyDialogueCatalog.decode(catalog(copy: copy))
        XCTAssertEqual(decoded.copy?.count, 1_024)
        XCTAssertEqual(try decoded.copyText("copy.1023"), "A local label")
    }

    func testCapacityAndPerEntryValidationStillRejectInvalidContent() throws {
        var copy = Dictionary(uniqueKeysWithValues: (0..<1_025).map { ("copy.\($0)", "A local label") })
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(catalog(copy: copy))) {
            XCTAssertEqual($0 as? SkyDialogueCatalog.ContentError, .invalidCatalog)
        }
        copy.removeValue(forKey: "copy.1024")
        copy["copy.1023"] = "A broken {template"
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(catalog(copy: copy))) {
            XCTAssertEqual($0 as? SkyDialogueCatalog.ContentError, .invalidCatalog)
        }
    }
}
