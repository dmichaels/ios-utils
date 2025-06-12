import SwiftUI

public struct ColorCircleIcon: View {
    public init() {}
    public var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                    center: .center
                )
            )
            .frame(width: 24, height: 24)
    }
}
