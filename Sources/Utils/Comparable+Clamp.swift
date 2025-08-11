extension Comparable {
    public func clamped(_ range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension BinaryFloatingPoint {
    public func clamped(_ range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
    public func clampedInt(_ range: ClosedRange<Self>) -> Int {
        Int(min(max(self, range.lowerBound), range.upperBound))
    }
}
