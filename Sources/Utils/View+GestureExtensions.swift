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
    internal let longTapThreshold: CGFloat
    internal let longTapPreemptTapThreshold: TimeInterval
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

    @State private var _dragStart: CGPoint? = nil
    @State private var _dragStartTime: Date? = nil
    @State private var _dragging: Bool = false
    @State private var _onLongTapTriggeredTime: Date? = nil

    internal func body(content: Content) -> some View {
        var result: AnyView = AnyView(content.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if (self._dragging) {
                        self.onDrag(normalizePoint?(value.location) ?? value.location)
                    }
                    else {
                        if (self._dragStart == nil) {
                            self._dragStartTime = Date()
                            self._dragStart = value.location
                        }
                        let dragDistance: CGFloat = hypot(value.location.x - self._dragStart!.x,
                                                          value.location.y - self._dragStart!.y)
                        if (dragDistance > self.dragThreshold) {
                            self._dragging = true
                            //
                            // Changed on 2025-07-27 to use self._dragStart rather than value.location
                            // for the onDrag call here; hopefully non-breaking but noting just in case.
                            // self.onDrag(normalizePoint?(value.location) ?? value.location)
                            //
                            self.onDrag(normalizePoint?(self._dragStart!) ?? self._dragStart!)
                        }
                    }
                }
                .onEnded { value in
                    if (self._dragging) {
                        var swipeLeft: Bool = false, swipeRight: Bool = false
                        if ((onSwipeLeft != nil) || (onSwipeRight != nil)) {
                            //
                            // If swipeDurationThreshold (in milliseconds from the API POV in onSmartGesture
                            // below) is greater than zero then we only recognize a swipe if its total time
                            // is less than or equal to that value; currently default to 500; i.e. we will
                            // only call onSwipe if the total swipe time is 500 milliseconds or less.
                            //
                            let swipeDuration: TimeInterval = (
                                (self.swipeDurationThreshold > 0.0) && (self._dragStartTime != nil)
                                ? Date().timeIntervalSince(self._dragStartTime!)
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
                                    swipeLeft = onSwipeLeft != nil
                                }
                                else if (swipeDistance > self.swipeThreshold) {
                                    swipeRight = onSwipeRight != nil
                                }
                            }
                        }
                        //
                        // Note that we need to call onDragEnd before onSwipe to avoid inconsistent state.
                        //
                        self.onDragEnd(normalizePoint?(value.location) ?? value.location)
                        if (swipeLeft) {
                            self.onSwipeLeft!()
                        }
                        else if (swipeRight) {
                            self.onSwipeRight!()
                        }
                    }
                    else {
                        //
                        // Guard against onTap being called immediately after onLongTap; to effectively
                        // disable this behavior pass longTapPreemptTapThreshold as 0 to onSmartGesture.
                        //
                        let onLongTapTriggeredRecently: Bool = (
                            self._onLongTapTriggeredTime != nil
                            ? Date().timeIntervalSince(self._onLongTapTriggeredTime!) < self.longTapPreemptTapThreshold
                            : false
                        )
                        self._onLongTapTriggeredTime = nil
                        if (!onLongTapTriggeredRecently) {
                            self.onTap(normalizePoint?(value.location) ?? value.location)
                        }
                    }
                    self._dragStart = nil
                    self._dragStartTime = nil
                    self._dragging = false
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
                                    //
                                    // If the point where the long tap began is too far from
                                    // where it ended then do not recognize it as a long tap.
                                    //
                                    if ((self._dragStart == nil) ||
                                        (hypot(location.x - self._dragStart!.x,
                                               location.y - self._dragStart!.y) <= longTapThreshold)) {
                                        self._onLongTapTriggeredTime = Date()
                                        self.onLongTap?(normalizePoint?(location) ?? location)
                                    }
                                }
                            default:
                                break
                        }
                    }
            ))
        }
        //
        // Note that SwiftUI does not seem to be able to guarantee the we will
        // get onEnded event for a MagnificationGesture; so the implementor is
        // advised not plan on doing anything particularly important there.
        //
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
}

public extension View {
    func onSmartGesture(dragThreshold: Int = 10, // milliseconds
                        swipeThreshold: Int = 100, // milliseconds
                        swipeDurationThreshold: Int = 700, // milliseconds
                        longTapThreshold: Int = 7, // pixels/points
                        longTapPreemptTapThreshold: Int = 50, // milliseconds
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
                        longTapThreshold: CGFloat(longTapThreshold),
                        longTapPreemptTapThreshold: TimeInterval(Double(longTapPreemptTapThreshold) / 1000.0),
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
