import SwiftUI

public class DefaultImage {

    public static let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue
    public static let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()

    public static let instance: CGImage = {
        return DefaultImage.context(width: 1, height: 1).makeImage()!
    }()

    public static func context(width: Int, height: Int) -> CGContext {
        return CGContext(data: nil, width: width, height: height,
                         bitsPerComponent: 8, bytesPerRow: width * Screen.channels,
                         space: DefaultImage.space, bitmapInfo: DefaultImage.bitmapInfo)!
    }

    public static func context(width: Int, height: Int, buffer: UnsafeMutableRawPointer) -> CGContext {
        return CGContext(data: buffer, width: width, height: height,
                         bitsPerComponent: 8, bytesPerRow: width * Screen.channels,
                         space: DefaultImage.space, bitmapInfo: DefaultImage.bitmapInfo)!
    }
}
