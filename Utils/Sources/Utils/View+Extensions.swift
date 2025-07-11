import SwiftUI

extension View {
    @ViewBuilder
    public func conditionalModifier<Content: View>(
        _ condition: Bool,
        apply: (Self) -> Content
    ) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    public func hide(_ hidden: Bool) -> some View {
        if hidden { EmptyView() } else { self }
    }
}
