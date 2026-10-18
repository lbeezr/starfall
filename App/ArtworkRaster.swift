import UIKit

/// Shared raster-coordinate alpha bounds for packaged art; never called per frame.
enum ArtworkRaster {
    static func alphaBounds(in image: CGImage, threshold: UInt8 = 0) -> CGRect? {
        let width = image.width, height = image.height
        guard width > 0, height > 0, width <= 4096, height <= 4096 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        return pixels.withUnsafeMutableBytes { bytes -> CGRect? in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            var minX = width, minY = height, maxX = -1, maxY = -1
            for y in 0..<height { for x in 0..<width where bytes[(y * width + x) * 4 + 3] > threshold {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            } }
            guard maxX >= minX, maxY >= minY else { return nil }
            return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        }
    }
}
