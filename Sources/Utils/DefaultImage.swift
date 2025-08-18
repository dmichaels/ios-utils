import SwiftUI

public class DefaultImage {
    public static let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue
    public static let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    public static let instance: CGImage = {
        return CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: DefaultImage.space, bitmapInfo: DefaultImage.bitmapInfo
        )!.makeImage()!
    }()
}
