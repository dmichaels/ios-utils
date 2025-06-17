import SwiftUI

// This is actually only currently used for the background color of the screen/image,
// i.e. for the backgound color if the inset margin is greater than zero.
//
public struct Colour: Equatable, Sendable
{
    // These values works with Utils.Memory.fastcopy NOT using value.bigEndian;
    // if these were the opposite (RSHIFT: 24, GSHIFT: 16, BSHIFT: 8, ALPHA: 0),
    // then we would need to use value.bigEndian there; slightly faster without.

    public static let RSHIFT: Int =  0
    public static let GSHIFT: Int =  8
    public static let BSHIFT: Int = 16
    public static let ASHIFT: Int = 24

    public static let RED:   UInt32 = 0xFF << Colour.RSHIFT
    public static let GREEN: UInt32 = 0xFF << Colour.GSHIFT
    public static let BLUE:  UInt32 = 0xFF << Colour.BSHIFT

    public static let OPAQUE:      UInt8 = 255
    public static let TRANSPARENT: UInt8 = 0

    // Private immutable individual RGBA color values.

    private let _red:   UInt8
    private let _green: UInt8
    private let _blue:  UInt8
    private let _alpha: UInt8

    // Sundry constructors.

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: UInt8 = Colour.OPAQUE) {
        self._red   = red
        self._green = green
        self._blue  = blue
        self._alpha = alpha
    }

    public init(_ red: Int, _ green: Int, _ blue: Int, alpha: Int = Int(Colour.OPAQUE)) {
        self._red   = UInt8(red)
        self._green = UInt8(green)
        self._blue  = UInt8(blue)
        self._alpha = UInt8(alpha)
    }

    public init(_ rgb: UInt32, alpha: UInt8 = Colour.OPAQUE) {
        self._red   = UInt8((rgb >> Colour.RSHIFT) & 0xFF)
        self._green = UInt8((rgb >> Colour.GSHIFT) & 0xFF)
        self._blue  = UInt8((rgb >> Colour.BSHIFT) & 0xFF)
        self._alpha = alpha
    }

    public init(_ color: Color) {
        //
        // N.B. Creating UIColor many times an be sloooooooooooooow. 
        // For example doing this 1200 * 2100 = 2,520,000 times can take
        // nearly 2 full seconds. Be careful to avoid this if/when possible.
        //
        self.init(UIColor(color))
    }

    private init(_ color: UIColor) {
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        var alpha: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self._red   = UInt8(red   * 255)
            self._green = UInt8(green * 255)
            self._blue  = UInt8(blue  * 255)
            self._alpha = UInt8(alpha * 255)
        }
        else {
            self._red   = 0
            self._green = 0
            self._blue  = 0
            self._alpha = Colour.OPAQUE
        }
    }

    // Readonly immutable property access.

    public var red:   UInt8 { self._red   }
    public var green: UInt8 { self._green }
    public var blue:  UInt8 { self._blue  }
    public var alpha: UInt8 { self._alpha }

    public var value: UInt32 {
        get {
            (UInt32(self._red)   << Colour.RSHIFT) |
            (UInt32(self._green) << Colour.GSHIFT) |
            (UInt32(self._blue)  << Colour.BSHIFT) |
            (UInt32(self._alpha) << Colour.ASHIFT)
        }
    }

    public var color: Color {
        Color(red: Double(self.red) / 255.0, green: Double(self.green) / 255.0, blue: Double(self.blue) / 255.0)
    }

    public var hex: String {
        String(format: "%02X", self.value)
    }

    // For convenience just replicate all known builtin UIColor colors.

    public static let black:     Colour = Colour(UIColor.black)
    public static let blue:      Colour = Colour(UIColor.blue)
    public static let brown:     Colour = Colour(UIColor.brown)
    public static let clear:     Colour = Colour(UIColor.clear)
    public static let cyan:      Colour = Colour(UIColor.cyan)
    public static let darkGray:  Colour = Colour(UIColor.darkGray)
    public static let gray:      Colour = Colour(UIColor.gray)
    public static let green:     Colour = Colour(UIColor.green)
    public static let lightGray: Colour = Colour(UIColor.lightGray)
    public static let magenta:   Colour = Colour(UIColor.magenta)
    public static let orange:    Colour = Colour(UIColor.orange)
    public static let purple:    Colour = Colour(UIColor.purple)
    public static let red:       Colour = Colour(UIColor.red)
    public static let white:     Colour = Colour(UIColor.white)
    public static let yellow:    Colour = Colour(UIColor.yellow)

    // For future use.

    public func tint(toward tint: Colour, by amount: CGFloat = 0.5) -> Colour {
        return Colour(Colour.tint(from: self.color, toward: tint.color, by: amount))
    }

    public func tint(toward tint: Color, by amount: CGFloat = 0.5) -> Colour {
        return Colour(Colour.tint(from: self.color, toward: tint, by: amount))
    }

    public func lighten(by amount: CGFloat = 0.3) -> Colour {
        Colour(Colour.lighten(self.color, by: amount))
    }

    public func darken(by amount: CGFloat = 0.3) -> Colour {
        Colour(Colour.darken(self.color, by: amount))
    }

    public static func tint(from: Color, toward tint: Color, by amount: CGFloat = 0.5) -> Color {
        let base: UIColor = UIColor(from)
        let tint: UIColor = UIColor(tint)
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        guard base.getRed(&br, green: &bg, blue: &bb, alpha: &ba),
              tint.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else {
            return from
        }
        return Color(red:     Double(br * (1 - amount) + tr * amount),
                     green:   Double(bg * (1 - amount) + tg * amount),
                     blue:    Double(bb * (1 - amount) + tb * amount),
                     opacity: Double(ba * (1 - amount) + ta * amount))
    }

    private static func lighten(_ color: Color, by amount: CGFloat) -> Color {
        let uicolor: UIColor = UIColor(color)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if uicolor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(hue: hue, saturation: saturation, brightness: min(brightness + amount, 1.0), opacity: alpha)
        }
        return color
    }

    private static func darken(_ color: Color, by amount: CGFloat) -> Color {
        let uicolor: UIColor = UIColor(color)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if uicolor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return Color(hue: hue, saturation: saturation, brightness: max(brightness - amount, 0), opacity: alpha)
        }
        return color
    }

    public static func random(mode: ColourMode = ColourMode.color,
                              tint: Colour? = nil, tintBy: CGFloat? = nil, filter: ColourFilter? = nil) -> Colour {
        var color: Colour
        if (mode == ColourMode.monochrome) {
            let value: UInt8 = UInt8.random(in: 0...1) * 255
            color = Colour(value, value, value)
        }
        else if (mode == ColourMode.grayscale) {
            let value: UInt8 = UInt8.random(in: 0...255)
            color = Colour(value, value, value)
        }
        else {
            let rgb: UInt32 = UInt32.random(in: 0...0xFFFFFF)
            color = Colour(UInt8((rgb >> Colour.RSHIFT) & 0xFF),
                           UInt8((rgb >> Colour.GSHIFT) & 0xFF),
                           UInt8((rgb >> Colour.BSHIFT) & 0xFF))
        }
        if (tint != nil) {
            color = color.tint(toward: tint!, by: tintBy ?? 0.5)
        }
        if (filter != nil) {
            color = Colour(filter!(color.value))
        }
        return color
    }
}

extension Color {
    //
    // This helper can be useful in a settings view with a ColorPicker.
    //
    public init(_ color: Colour) {
        self.init(.sRGB, red: Double(color.red) / 255.0,
                         green: Double(color.green) / 255.0,
                         blue: Double(color.blue) / 255.0,
                         opacity: Double(color.alpha) / 255.0)
    }
}
