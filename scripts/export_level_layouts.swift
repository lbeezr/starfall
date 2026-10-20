import Foundation
import CoreGraphics
import StarfallCore

/// Authoring data from the app's actual geometry owner, not a second layout formula.
@main enum ExportLevelLayouts {
    static func rectangle(_ rect: CGRect) -> [String: Double] {
        ["x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height]
    }

    static func main() throws {
        let references: [(String, CGFloat, CGFloat, Bool)] = [
            ("phone", 393, 852, false),
            ("ipad-portrait", 768, 1024, false),
            ("ipad-landscape", 1024, 768, false),
            ("phone-expanded", 375, 900, false),
            ("phone-accessibility", 393, 1200, true),
            ("ipad-accessibility", 1024, 1200, true)
        ]
        let layouts: [[String: Any]] = references.map { name, width, height, large in
            let geometry = LandingGeometry(size: CGSize(width: width, height: height), largeHeader: large)
            return ["id": name, "width": width, "height": height, "largeHeader": large,
                    "board": rectangle(geometry.arenaFrame),
                    // These remain geometry references, not current SwiftUI coverage.
                    // FallingSkyView places measured chrome at the viewport edges.
                    "legacyGeometryReservations": [
                        "header": rectangle(geometry.crownFrame),
                        "dialogue": rectangle(geometry.communicationContentFrame),
                        "actions": [rectangle(geometry.actionFrame(0)), rectangle(geometry.actionFrame(1))]
                    ],
                    "cellStep": geometry.starStep, "accessibleCanvasEnd": geometry.accessibleCanvasEnd,
                    "cells": (0..<7).flatMap { row in (0..<7).map { column in
                        ["row": row, "column": column, "frame": rectangle(geometry.frame(Cell(row, column)))] as [String: Any]
                    }}]
        }
        let data = try JSONSerialization.data(withJSONObject: ["schemaVersion": 2, "layouts": layouts], options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
