import SwiftUI

public struct Display
{
    public let channels: Int = 4
    public let scale: CGFloat
    public let size: CGSize
    public let width: Int
    public let height: Int

    public init(size: CGSize, scale: CGFloat) {
        self.scale = scale
        self.size = size
        self.width = Int(floor(size.width))
        self.height = Int(floor(size.height))
    }

    public func scale(_ value: Int) -> Int { Int(round(CGFloat(value) * self.scale)) }
    public func unscale(_ value: Int) -> Int { Int(round(CGFloat(value) / self.scale)) }

    public func scale(_ value: Int, scaling: Bool) -> Int { scaling ? self.scale(value) : value }
    public func unscale(_ value: Int, scaling: Bool) -> Int { scaling ? self.unscale(value) : value }

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
