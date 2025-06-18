import SwiftUI

public struct ColorCircleIcon: View {
    private let _size: CGFloat
    public init(size: CGFloat = 20.0) { self._size = size }
    public var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                    center: .center
                )
            )
            .frame(width: self._size, height: self._size)
    }
}
