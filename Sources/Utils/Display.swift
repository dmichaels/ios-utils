import SwiftUI

@MainActor
public enum Display
{
    public static let channels: Int = 4
    public static let scale: CGFloat = UIScreen.main.scale
    public static let size: CGSize = UIScreen.main.bounds.size
    public static let width: Int = Int(floor(Display.size.width))
    public static let height: Int = Int(floor(Display.size.height))

    public static func scale(_ value: Int) -> Int { Int(round(CGFloat(value) * Display.scale)) }
    public static func unscale(_ value: Int) -> Int { Int(round(CGFloat(value) / Display.scale)) }

    public static func scale(_ value: Int, scaling: Bool) -> Int { scaling ? Display.scale(value) : value }
    public static func unscale(_ value: Int, scaling: Bool) -> Int { scaling ? Display.unscale(value) : value }

    // Returns the scaled and unscaled values for the given value as a tuple (in that order),
    // based on whether or not the given value is scaled, and whether or not we (our caller) is
    // currently in "scaling mode" (i.e. whether or not we want a scaled value as the scaled result).
    //
    public static func scaler(_ value: Int, scaled: Bool, scaling: Bool) -> (Int, Int) {
        if (scaled) {
            if (scaling) {
                return (value, Display.unscale(value))
            }
            else {
                let unscaledValue: Int = Display.unscale(value)
                return (unscaledValue, unscaledValue)
            }
        }
        else if (scaling) {
            return (Display.scale(value), value)
        }
        else {
            return (value, value)
        }
    }

    // Same-as/uses above but assigns the scaled/unscaled values from the tuple to the given inout arguments.
    //
    public static func scaler(_ value: Int, _ scaledValue: inout Int,
                                            _ unscaledValue: inout Int, scaled: Bool, scaling: Bool) {
        (scaledValue, unscaledValue) = Display.scaler(value, scaled: scaled, scaling: scaling)
    }
}
