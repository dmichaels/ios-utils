import SwiftUI

public struct SettingsSection<Content: View>: View {

    let _title: String
    let _icon: String?
    let _vspace: Int?
    let _content: () -> Content

    public init(_ title: String? = nil, icon: String? = nil, vspace: Int? = nil, @ViewBuilder content: @escaping () -> Content) {
        self._title = title ?? ""
        self._icon = icon
        self._content = content
        self._vspace = vspace
    }

    public var body: some View {
        Section(header:
            HStack {
                Text(self._title)
                if let icon = self._icon {
                    Image(systemName: icon).offset(y: -2)
                }
            }
            .padding(.leading, -12)
            .padding(.top, CGFloat(self._vspace ?? -20))
        )
        {
            self._content()
        }
    }
}
