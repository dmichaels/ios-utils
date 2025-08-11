import SwiftUI

public struct IconLabel: View {

    private var _text: String
    private var _icon: String
    private var _iconWidth: CGFloat
    private var _compact: Bool
    @Environment(\.isEnabled) private var isEnabled: Bool

    public init(_ text: String, _ icon: String, iconWidth: CGFloat = 32.0, compact: Bool = true) {
        self._text = text
        self._icon = icon
        self._iconWidth = iconWidth
        self._compact = compact
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if (self._icon.uppercased() == "COLOR") {
                ColorCircleIcon().frame(width: self._iconWidth, alignment: .leading)
                    .padding(.leading, self._compact ? -4 : 0)
                    .foregroundColor(isEnabled ? .primary : .gray)
            }
            else {
                Image(systemName: self._icon).frame(width: self._iconWidth, alignment: .leading)
                    .padding(.leading, self._compact ? -4 : 0)
                    .foregroundColor(isEnabled ? .primary : .gray)
            }
            Text(self._text)
                .alignmentGuide(.leading) { d in d[.leading] }
                .padding(.leading, self._compact ? -4 : 0)
                .fixedSize()
                .layoutPriority(1)
                .foregroundColor(isEnabled ? .primary : .gray)
            Spacer()
        }
    }
}
