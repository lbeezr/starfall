import XCTest
import UIKit
@testable import Starfall

final class LaunchSurfaceTests: XCTestCase {
    @MainActor func testPackagedLaunchSurfaceIsOpaqueDarkInBothAppearances() throws {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String, "LaunchScreen")
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "UILaunchScreen"))
        let controller = try XCTUnwrap(UIStoryboard(name: "LaunchScreen", bundle: bundle).instantiateInitialViewController())
        let title = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(title.text, "Starfall")
        XCTAssertEqual(title.textColor, UIColor(named: "CeremonyGold", in: bundle, compatibleWith: nil))
        let background = try XCTUnwrap(controller.view.backgroundColor)
        let named = try XCTUnwrap(UIColor(named: "LaunchBackground", in: bundle, compatibleWith: nil))
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let resolved = background.resolvedColor(with: traits)
            XCTAssertEqual(resolved, named.resolvedColor(with: traits))
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            XCTAssertEqual(alpha, 1)
            XCTAssertLessThan(max(red, green, blue), 0.2)
        }
    }
}
