public typealias ColourFilterType = (UInt32) -> UInt32

public struct ColourFilters
{
    public static func None(value: UInt32) -> UInt32 { return value }

    public static func Reds(value: UInt32) -> UInt32 { return ROO(value: value) }
    public static func Redish(value: UInt32) -> UInt32 { return XGB(value: value) }
    public static func Redless(value: UInt32) -> UInt32 { return OGB(value: value) }

    public static func Greens(value: UInt32) -> UInt32 { return OGO(value: value) }
    public static func Greenish(value: UInt32) -> UInt32 { return RXB(value: value) }
    public static func Greenless(value: UInt32) -> UInt32 { return ROB(value: value) }

    public static func Blues(value: UInt32) -> UInt32 { return OOB(value: value) }
    public static func Bluish(value: UInt32) -> UInt32 { return RGX(value: value) }
    public static func Blueish(value: UInt32) -> UInt32 { return RGX(value: value) }
    public static func Blueless(value: UInt32) -> UInt32 { return RGO(value: value) }

    public static func RGB(value: UInt32) -> UInt32 { return value }
    public static func RGX(value: UInt32) -> UInt32 { return value | B }
    public static func RGO(value: UInt32) -> UInt32 { return value & (R | G) }
    public static func RXB(value: UInt32) -> UInt32 { return value | G }
    public static func RXX(value: UInt32) -> UInt32 { return value | (G | B) }
    public static func RXO(value: UInt32) -> UInt32 { return value & (R | G) }
    public static func ROB(value: UInt32) -> UInt32 { return value & (R | B) }
    public static func ROX(value: UInt32) -> UInt32 { return (value & (R | B)) & B }
    public static func ROO(value: UInt32) -> UInt32 { return value & R }
    public static func XGB(value: UInt32) -> UInt32 { return value | R }
    public static func XGX(value: UInt32) -> UInt32 { return value | (R | B) }
    public static func XGO(value: UInt32) -> UInt32 { return (value | R) & (R | G) }
    public static func XXB(value: UInt32) -> UInt32 { return value | (R | G) }
    public static func XXX(value: UInt32) -> UInt32 { return value | (R | G | B) }
    public static func XXO(value: UInt32) -> UInt32 { return (value | (R | G)) & (R | G) }
    public static func XOB(value: UInt32) -> UInt32 { return (value | R) & (R | B) }
    public static func XOX(value: UInt32) -> UInt32 { return (value | (R | B)) & (R | B) }
    public static func XOO(value: UInt32) -> UInt32 { return (value | R) & R }
    public static func OGB(value: UInt32) -> UInt32 { return value & (G | B) }
    public static func OGX(value: UInt32) -> UInt32 { return (value & (G | B)) | B }
    public static func OGO(value: UInt32) -> UInt32 { return value & G }
    public static func OXB(value: UInt32) -> UInt32 { return (value & (G | B)) | G }
    public static func OXX(value: UInt32) -> UInt32 { return (value & (G | B)) | (G | B) }
    public static func OXO(value: UInt32) -> UInt32 { return (value & G) | G }
    public static func OOB(value: UInt32) -> UInt32 { return value & B }
    public static func OOX(value: UInt32) -> UInt32 { return (value & B) | B }
    public static func OOO(value: UInt32) -> UInt32 { return value & 0x000000 }

    private static let R: UInt32 = Colour.RED
    private static let G: UInt32 = Colour.GREEN
    private static let B: UInt32 = Colour.BLUE
}
