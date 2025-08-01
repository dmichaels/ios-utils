import SwiftUI

// The onSmartGesture view modifier consolidates various gestures. Usage like something like this:
//  
//    .onSmartGesture(dragThreshold: self.dragThreshold,
//                    normalizePoint: self.normalizePoint,
//        onTap:       { value in self.onTap(value) },
//        onLongTap:   { value in self.onLongTap(value) },
//        onDoubleTap: { value in self.onDoubleTap(value) },
//        onDrag:      { value in self.onDrag(value) },
//        onDragEnd:   { value in self.onDragEnd(value) },
//        onZoom:      { value in self.onZoom(value) },
//        onZoomEnd:   { value in self.onZoomEnd(value) }
//    )
//
// N.B. This was inspired by ChatGPT FYI FBOW FWIW.
//
public extension View {
    func onSmartGesture(dragThreshold: Int = 4, // pixels/points
                        swipeThreshold: Int = 100, // pixels/points
                        swipeDurationThreshold: Int = 700, // milliseconds
                        longTapThreshold: Int = 6, // pixels/points
                        longTapPreemptTapThreshold: Int = 50, // milliseconds
                        normalizePoint: ((CGPoint) -> CGPoint)? = nil,
                        ignorePoint: ((CGPoint) -> Bool)? = nil,
                        orientation: OrientationObserver? = nil,
                        onTap: @escaping (CGPoint) -> Void = { _ in },
                        onLongTap: ((CGPoint) -> Void)? = nil,
                        onDoubleTap: ((CGPoint?) -> Void)? = nil,
                        onDrag: @escaping (CGPoint) -> Void = { _ in },
                        onDragEnd: @escaping (CGPoint) -> Void = { _ in },
                        onDragStrict: Bool = false,
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
                        ignorePoint: ignorePoint,
                        orientation: orientation,
                        onTap: onTap,
                        onLongTap: onLongTap,
                        onDoubleTap: onDoubleTap,
                        onDrag: onDrag,
                        onDragEnd: onDragEnd,
                        onDragStrict: onDragStrict,
                        onZoom: onZoom,
                        onZoomEnd: onZoomEnd,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight))
    }
}

private struct SmartGesture: ViewModifier
{
    internal let dragThreshold: CGFloat
    internal let swipeThreshold: CGFloat
    internal let swipeDurationThreshold: TimeInterval
    internal let longTapThreshold: CGFloat
    internal let longTapPreemptTapThreshold: TimeInterval
    internal let normalizePoint: ((CGPoint) -> CGPoint)?
    internal let ignorePoint: ((CGPoint) -> Bool)?
    internal let orientation: OrientationObserver?
    internal let onTap: (CGPoint) -> Void
    internal let onLongTap: ((CGPoint) -> Void)?
    internal let onDoubleTap: ((CGPoint?) -> Void)?
    internal let onDrag: (CGPoint) -> Void
    internal let onDragEnd: (CGPoint) -> Void
    internal let onDragStrict: Bool
    internal let onZoom: ((CGFloat) -> Void)?
    internal let onZoomEnd: ((CGFloat) -> Void)?
    internal let onSwipeLeft: (() -> Void)?
    internal let onSwipeRight: (() -> Void)?

    @State private var _dragStart: CGPoint? = nil
    @State private var _dragStartTime: Date? = nil
    @State private var _dragging: Bool = false
    @State private var _onLongTapTriggeredTime: Date? = nil

    private func _normalizePoint(_ point: CGPoint) -> CGPoint? {
        //
        // Introduced ignorePoint (2025-07-31); useful for example to limit gestures which are targeted
        // for an Image inside a container (e.g. ZStack) but where the image is smaller; in such a case,
        // for reasons as yet not completely understood, we can get gestures notification outside of the
        // image (even though the onSmartGesture is placed on the Image); note that this acts on the
        // normalized point, if normalizedPoint is indeed specified. And this ignorePoint is applicable
        // only for onTap/onLongTap/onDoubleTap, or, if onDragStrict is true, then also onDrag.
        //
        let point: CGPoint = self.normalizePoint?(point) ?? point
        return (self.ignorePoint?(point) ?? false) ? nil : point
    }

    internal func body(content: Content) -> some View {
        var result: AnyView = AnyView(content.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if (self.onDragStrict) {
                        //
                        // Probably best not to check the validity of the location/point via ignorePoint once
                        // dragging has started; but can onDragStrict can be set to true to get the more strict
                        // behavior; though even in this case a drag could be started outside the desired bounds,
                        // i.e. at a point where ignorePoint returns true, and onDrag would still be called if
                        // the drag proceeds into the desired bounds, i.e where ignorePoint returns false.
                        // Also note that _dragStart here has the non-normalized point.
                        //
                        guard let _ = self._normalizePoint(value.location) else {
                            return
                        }
                    }
                    if (self._dragging) {
                        self.onDrag(self.normalizePoint?(value.location) ?? value.location)
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
                            self.onDrag(self.normalizePoint?(self._dragStart!) ?? self._dragStart!)
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
                        self.onDragEnd(self.normalizePoint?(value.location) ?? value.location)
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
                            if let point: CGPoint = self._normalizePoint(value.location) {
                                self.onTap(point)
                            }
                        }
                    }
                    self._dragStart = nil
                    self._dragStartTime = nil
                    self._dragging = false
                }
        ))
        if let onLongTap: ((CGPoint) -> Void) = self.onLongTap {
            result = AnyView(result.simultaneousGesture(
                LongPressGesture(minimumDuration: 1.0)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        switch value {
                            case .second(true, let drag):
                                if let location: CGPoint = drag?.location {
                                    //
                                    // If the point where the long tap began is too far from
                                    // where it ended then do not recognize it as a long tap.
                                    //
                                    if ((self._dragStart == nil) ||
                                        (hypot(location.x - self._dragStart!.x,
                                               location.y - self._dragStart!.y) <= longTapThreshold)) {
                                        self._onLongTapTriggeredTime = Date()
                                        if let point: CGPoint = self._normalizePoint(location) {
                                            onLongTap(point)
                                        }
                                    }
                                }
                            default:
                                break
                        }
                    }
            ))
        }
        if let onDoubleTap: ((CGPoint?) -> Void) = self.onDoubleTap {
            if #available(iOS 17.0, *) {
                result = AnyView(result.simultaneousGesture(
                    //
                    // New (2025-07-31) usage of SpatialTapGesture
                    // to get the location/point of the double-tap.
                    //
                    SpatialTapGesture(count: 2)
                        .onEnded { value in
                            if let point: CGPoint = self._normalizePoint(value.location) {
                                onDoubleTap(point)
                            }
                        }
                ))
            } else {
                result = AnyView(result.simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            onDoubleTap(nil)
                        }
                ))
            }
        }
        //
        // Note that SwiftUI does not seem to be able to guarantee the we will
        // get onEnded event for a MagnificationGesture; so the implementor is
        // advised not plan on doing anything particularly important there.
        //
        if let onZoom: ((CGFloat) -> Void) = self.onZoom {
            if let onZoomEnd: ((CGFloat) -> Void) = self.onZoomEnd {
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
        else if let onZoomEnd: ((CGFloat) -> Void) = self.onZoomEnd {
            result = AnyView(result.simultaneousGesture(
                MagnificationGesture()
                    .onEnded(onZoomEnd)
            ))
        }
        return result
    }
}
