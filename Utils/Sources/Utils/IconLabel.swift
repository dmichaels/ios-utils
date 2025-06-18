import SwiftUI

public struct IconLabel: View {
    private var _text: String
    private var _icon: String
    private var _iconWidth: CGFloat
    public init(_ text: String, _ icon: String, iconWidth: CGFloat = 32.0) {
        self._text = text
        self._icon = icon
        self._iconWidth = iconWidth
    }
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if (self._icon == "COLOR") {
                ColorCircleIcon().frame(width: self._iconWidth, alignment: .leading)
            }
            else {
                Image(systemName: self._icon).frame(width: self._iconWidth, alignment: .leading)
            }
            Text(self._text)
                .alignmentGuide(.leading) { d in d[.leading] }
                .fixedSize()
                .layoutPriority(1)
            Spacer()
        }
    }
}
