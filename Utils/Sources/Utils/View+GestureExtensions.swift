import SwiftUI

// Consolidated various gestures. Usage like thisa:
//  
//    .onSmartGesture(dragThreshold: self.dragThreshold,
//                    normalizePoint: self.normalizePoint,
//        onDrag:      { value in self.onDrag(value) },
//        onDragEnd:   { value in self.onDragEnd(value) },
//        onTap:       { value in self.onTap(value) },
//        onDoubleTap: { self.onDoubleTap() },
//        onLongTap:   { value in self.onLongTap(value) },
//        onZoom:      { value in self.onZoom(value) },
//        onZoomEnd:   { value in self.onZoomEnd(value) }
//    )
//
// N.B. This was inspired by ChatGPT.
//
private struct SmartGesture: ViewModifier
{

    internal let dragThreshold: CGFloat
    internal let swipeThreshold: CGFloat
    internal let swipeDurationThreshold: TimeInterval
    internal let normalizePoint: ((CGPoint) -> CGPoint)?
    internal let orientation: OrientationObserver?
    internal let onDrag: (CGPoint) -> Void
    internal let onDragEnd: (CGPoint) -> Void
    internal let onTap: (CGPoint) -> Void
    internal let onDoubleTap: (() -> Void)?
    internal let onLongTap: ((CGPoint) -> Void)?
    internal let onZoom: ((CGFloat) -> Void)?
    internal let onZoomEnd: ((CGFloat) -> Void)?
    internal let onSwipeLeft: (() -> Void)?
    internal let onSwipeRight: (() -> Void)?

    @State private var dragStart: CGPoint? = nil
    @State private var dragStartTime: Date? = nil
    @State private var dragging: Bool = false

    internal func body(content: Content) -> some View {
        var result: AnyView = AnyView(content.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if (dragging) {
                        self.onDrag(normalizePoint?(value.location) ?? value.location)
                    }
                    else {
                        if (dragStart == nil) {
                            dragStartTime = Date()
                            dragStart = value.location
                        }
                        if (SmartGesture.dragDistance(start: dragStart!, current: value.location) > self.dragThreshold) {
                            dragging = true
                            self.onDrag(normalizePoint?(value.location) ?? value.location)
                        }
                    }
                }
                .onEnded { value in
                    if (dragging) {
                        var swipped: Bool = false
                        if ((onSwipeLeft != nil) || (onSwipeRight != nil)) {
                            //
                            // If swipeDurationThreshold (in milliseconds from the API POV in onSmartGesture
                            // below) is greater than zero then we only recognize a swipe if its total time
                            // is less than or equal to that value; currently default to 500; i.e. we will
                            // only call onSwipe if the total swipe time is 500 milliseconds or less.
                            //
                            let swipeDuration: TimeInterval = (
                                (self.swipeDurationThreshold > 0.0) && (self.dragStartTime != nil)
                                ? Date().timeIntervalSince(self.dragStartTime!)
                                : 0
                            )
                            //
                            // Some weird nonsense with upside-down orientation; even when not supported.
                            //
                            let upsideDown: Bool = (
                                (self.orientation != nil) &&
                                (self.orientation!.current == .portraitUpsideDown)
                            )
                            let upsideDownButNotActuallySupported: Bool = (
                                upsideDown &&
                                !self.orientation!.supported.contains(.portraitUpsideDown)
                            )
                            if (!upsideDownButNotActuallySupported && (swipeDuration <= self.swipeDurationThreshold)) {
                                let swipeDistance: CGFloat = (
                                    upsideDown ? value.translation.width : value.translation.width
                                )
                                if (swipeDistance < -self.swipeThreshold) {
                                    self.onSwipeLeft?()
                                    swipped = true
                                }
                                else if (swipeDistance > self.swipeThreshold) {
                                    self.onSwipeRight?()
                                    swipped = true
                                }
                            }
                        }
                        if (!swipped) {
                            self.onDragEnd(normalizePoint?(value.location) ?? value.location)
                        }
                    }
                    else {
                        self.onTap(normalizePoint?(value.location) ?? value.location)
                    }
                    dragStart = nil
                    dragStartTime = nil
                    dragging = false
                }
        ))
        if let onDoubleTap = self.onDoubleTap {
            result = AnyView(result.simultaneousGesture(
                TapGesture(count: 2).onEnded(onDoubleTap)
            ))
        }
        if let onLongTap = self.onLongTap {
            result = AnyView(result.simultaneousGesture(
                LongPressGesture(minimumDuration: 1.0)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        switch value {
                            case .second(true, let drag):
                                if let location = drag?.location {
                                    self.onLongTap?(normalizePoint?(location) ?? location)
                                }
                            default:
                                break
                        }
                    }
            ))
        }
        if let onZoom = self.onZoom {
            if let onZoomEnd = self.onZoomEnd {
                result = AnyView(result.simultaneousGesture(
                    MagnificationGesture()
                        .onChanged(onZoom)
                        .onEnded(onZoomEnd)
                ))
            }
            else {
                result = AnyView(result.simultaneousGesture(
                    MagnificationGesture()
                        .onChanged(onZoom)
                ))
            }
        }
        else if let onZoomEnd = self.onZoomEnd {
            result = AnyView(result.simultaneousGesture(
                MagnificationGesture()
                    .onEnded(onZoomEnd)
            ))
        }
        return result
    }

    private static func dragDistance(start: CGPoint, current: CGPoint) -> CGFloat {
        return hypot(current.x - start.x, current.y - start.y)
    }
}

public extension View {
    func onSmartGesture(dragThreshold: Int = 10,
                        swipeThreshold: Int = 100,
                        swipeDurationThreshold: Int = 500,
                        normalizePoint: ((CGPoint) -> CGPoint)? = nil,
                        orientation: OrientationObserver? = nil,
                        onDrag: @escaping (CGPoint) -> Void = { _ in },
                        onDragEnd: @escaping (CGPoint) -> Void = { _ in },
                        onTap: @escaping (CGPoint) -> Void = { _ in },
                        onDoubleTap: (() -> Void)? = nil,
                        onLongTap: ((CGPoint) -> Void)? = nil,
                        onZoom: ((CGFloat) -> Void)? = nil,
                        onZoomEnd: ((CGFloat) -> Void)? = nil,
                        onSwipeLeft: (() -> Void)? = nil,
                        onSwipeRight: (() -> Void)? = nil,
    ) -> some View {
        self.modifier(SmartGesture(
                        dragThreshold: CGFloat(dragThreshold),
                        swipeThreshold: CGFloat(swipeThreshold),
                        swipeDurationThreshold: TimeInterval(Double(swipeDurationThreshold) / 1000.0),
                        normalizePoint: normalizePoint,
                        orientation: orientation,
                        onDrag: onDrag,
                        onDragEnd: onDragEnd,
                        onTap: onTap,
                        onDoubleTap: onDoubleTap,
                        onLongTap: onLongTap,
                        onZoom: onZoom,
                        onZoomEnd: onZoomEnd,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight))
    }
}
