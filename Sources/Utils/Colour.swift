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

    private static let OPAQUE_FLOAT: Float = Float(Colour.OPAQUE)

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

    public init(_ color: UIColor) {
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        var alpha: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self._red   = UInt8(max(0, min(255, red   * 255)))
            self._green = UInt8(max(0, min(255, green * 255)))
            self._blue  = UInt8(max(0, min(255, blue  * 255)))
            self._alpha = UInt8(max(0, min(255, alpha * 255)))
        }
        else {
            self._red   = 0
            self._green = 0
            self._blue  = 0
            self._alpha = Colour.OPAQUE
        }
    }

    public init(_ color: CGColor) {
        self.init(UIColor(cgColor: color))
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

    public var uicolor: UIColor {
        UIColor(self.color)
    }

    public var cgcolor: CGColor {
        self.uicolor.cgColor
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

    public func opacity(_ alpha: UInt8) -> Colour {
        return Colour(self.red, self.green, self.blue, alpha: alpha)
    }

    public func opacity(_ alpha: Int) -> Colour {
        let alpha: UInt8 = UInt8(min(max(alpha, 0), 255))
        return Colour(self.red, self.green, self.blue, alpha: alpha)
    }

    public func opacity(_ alpha: Float) -> Colour {
        let alpha: UInt8 = UInt8(min(max(alpha, 0.0), 1.0) * Colour.OPAQUE_FLOAT)
        return Colour(self.red, self.green, self.blue, alpha: alpha)
    }

    public func transparency(_ alpha: UInt8) -> Colour {
        return Colour(self.red, self.green, self.blue, alpha: 255 - alpha)
    }

    public func transparency(_ alpha: Float) -> Colour {
        let alpha: UInt8 = UInt8(min(max(alpha, 0.0), 1.0) * Colour.OPAQUE_FLOAT)
        return Colour(self.red, self.green, self.blue, alpha: 255 - alpha)
    }

    // Tints (this base) Colour toward the given Colour by the given amount which is assumed to, and is
    // clamped to be, in the (inclusive) range of 0.0 thru 1.0. If the opacity argument is true (default)
    // then the opacity is taken into account (of both the tint color and this base color); otherwise,
    // if opacity is false, then it is not (the opacity simply remains what it was for this base color).
    //
    public func tint(toward tint: Colour, by amount: Float? = nil, opacity: Bool = true) -> Colour {
        let amount:  Float = amount != nil ? min(max(amount!, 0.0), 1.0) : 0.5
        let factor:  Float = opacity ? amount * (Float(tint.alpha) / 255.0) : amount
        let ifactor: Float = 1.0 - factor
        let red:     UInt8   = UInt8(round(Float(self.red)   * ifactor + Float(tint.red)   * factor))
        let green:   UInt8   = UInt8(round(Float(self.green) * ifactor + Float(tint.green) * factor))
        let blue:    UInt8   = UInt8(round(Float(self.blue)  * ifactor + Float(tint.blue)  * factor))
        let opacity: UInt8   = opacity ? UInt8(round(Float(self.alpha) * ifactor + Float(tint.alpha) * factor)) : self.alpha
        return Colour(red, green, blue, alpha: opacity)
    }

    public func tint(toward tint: Color, by amount: Float? = nil, opacity: Bool = true) -> Colour {
        return Colour(tint).tint(toward: Colour(tint), by: amount, opacity: opacity)
    }

    public func lighten(by amount: Float) -> Colour {
        let amount: CGFloat = CGFloat(amount)
        let factor: CGFloat = min(max(amount, 0.0), 1.0)
        let ifactor: CGFloat = 1.0 - factor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.uicolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let bred:   CGFloat = (red   * ifactor) + factor
        let bgreen: CGFloat = (green * ifactor) + factor
        let bblue:  CGFloat = (blue  * ifactor) + factor
        return Colour(Color(red: bred, green: bgreen, blue: bblue, opacity: alpha))
    }

    public func darken(by amount: Float) -> Colour {
        let amount: CGFloat = CGFloat(amount)
        let ifactor = 1.0 - min(max(amount, 0.0), 1.0)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.uicolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let fred:   CGFloat = red   * ifactor
        let fgreen: CGFloat = green * ifactor
        let fblue:  CGFloat = blue  * ifactor
        return Colour(Color(red: fred, green: fgreen, blue: fblue, opacity: alpha))
    }

    public var isLight: Bool {
        !isDark
    }

    public var isDark: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard self.uicolor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return false
        }
        let brightness = 0.299 * red + 0.587 * green + 0.114 * blue
        return brightness < 0.5
    }

    public static func random(mode: ColourPalette = ColourPalette.color,
                              tint: Colour? = nil, tintBy: Float = 0.5,
                              lighten: Float? = nil,
                              darken: Float? = nil,
                              filter: ColourFilter? = nil) -> Colour {
        var color: Colour
        if (mode == ColourPalette.monochrome) {
            let value: UInt8 = UInt8.random(in: 0...1) * 255
            color = Colour(value, value, value)
        }
        else if (mode == ColourPalette.grayscale) {
            let value: UInt8 = UInt8.random(in: 0...255)
            color = Colour(value, value, value)
        }
        else {
            let rgb: UInt32 = UInt32.random(in: 0...0xFFFFFF)
            color = Colour(UInt8((rgb >> Colour.RSHIFT) & 0xFF),
                           UInt8((rgb >> Colour.GSHIFT) & 0xFF),
                           UInt8((rgb >> Colour.BSHIFT) & 0xFF))
        }
        if (tint != nil)    { color = color.tint(toward: tint!, by: tintBy) }
        if (lighten != nil) { color = color.lighten(by: lighten!) }
        if (darken != nil)  { color = color.darken(by: darken!) }
        if (filter != nil)  { color = Colour(filter!(color.value)) }
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

extension Binding where Value == Colour {
    //
    // This is so we can use our Colour wrapper in a Color Picker, e.g.:
    // ColorPicker("", selection: $settings.background.picker)
    //
    public var picker: Binding<Color> {
        Binding<Color>(
            get: { Color(self.wrappedValue) },
            set: { self.wrappedValue = Colour($0) }
        )
    }
}
