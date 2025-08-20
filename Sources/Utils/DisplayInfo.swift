import SwiftUI

// This common utility DisplayInfo class is intended to be created with something like:
//
//      DisplayInfo(size: UIScreen.main.bounds.size, scale: UIScreen.main.scale)
//
// It is not done so here, i.e. e.g. by providing a static/instance singleton, due to
// complications with such a usage requiring we mark the class as @MainActor, which can
// cause cascading problems requiring using classes also requiring this specifier, et cetera.
//
public struct DisplayInfo
{
    public        let size: CGSize
    public        let width: Int
    public        let height: Int
    public        let scale: CGFloat
    public        let channels: Int = DisplayInfo.channels
    public static let channels: Int = 4

    public init(size: CGSize, scale: CGFloat) {
        self.scale = scale
        self.size = size
        self.width = Int(floor(size.width))
        self.height = Int(floor(size.height))
    }

    public init(bounds: CGRect, scale: CGFloat) {
        self.init(size: bounds.size, scale: scale)
    }

    public init(width: CGFloat, height: CGFloat, scale: CGFloat) {
        self.init(size: CGSize(width: width, height: height), scale: scale)
    }

    public init(width: Int, height: Int, scale: CGFloat) {
        self.init(size: CGSize(width: width, height: height), scale: scale)
    }

    public func scale(_ value: Int) -> Int { Int(round(CGFloat(value) * self.scale)) }
    public func scale(_ value: CGFloat) -> CGFloat { value * self.scale }
    public func scale(_ value: Int, scaling: Bool) -> Int { scaling ? self.scale(value) : value }
    public func scale(_ value: CGFloat, scaling: Bool) -> CGFloat { scaling ? self.scale(value) : value }

    public func unscale(_ value: Int) -> Int { Int(round(CGFloat(value) / self.scale)) }
    public func unscale(_ value: CGFloat) -> CGFloat { value / self.scale }
    public func unscale(_ value: Int, scaling: Bool) -> Int { scaling ? self.unscale(value) : value }
    public func unscale(_ value: CGFloat, scaling: Bool) -> CGFloat { scaling ? self.unscale(value) : value }

    // Returns the scaled and unscaled values for the given value as a tuple (in that order),
    // based on whether or not the given value is scaled, and whether or not we (our caller) is
    // currently in "scaling mode" (i.e. whether or not we want a scaled value as the scaled result).
    //
    public func scaler(_ value: Int, scaled: Bool, scaling: Bool) -> (Int, Int) {
        if (scaled) {
            if (scaling) {
                return (value, self.unscale(value))
            }
            else {
                let unscaledValue: Int = self.unscale(value)
                return (unscaledValue, unscaledValue)
            }
        }
        else if (scaling) {
            return (self.scale(value), value)
        }
        else {
            return (value, value)
        }
    }

    // Same-as/uses above but assigns the scaled/unscaled values from the tuple to the given inout arguments.
    //
    public func scaler(_ value: Int, _ scaledValue: inout Int,
                                     _ unscaledValue: inout Int, scaled: Bool, scaling: Bool) {
        (scaledValue, unscaledValue) = self.scaler(value, scaled: scaled, scaling: scaling)
    }
}
