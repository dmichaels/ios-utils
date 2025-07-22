import Foundation
import QuartzCore

// This ScheduledTimer wraps the standard Timer class and optionally supports the lower-level,
// supposedly faster, timers CADisplayLink and DispatchSourceTimer. But actually does not seem
// to be any faster. Came up with ios-lifegame app supporting "undulating" mode where we wanted
// a sort of demo-mode to automatically resize the cell-grid larger/smaller rapidly like it was
// automatically doing a zoom in/out gesture.
//
public final class ScheduledTimer
{
    public enum Mode {
        case scheduledTimer
        case displayTimer
        case dispatchTimer
    }

    private var _timer: Timer?
    private var _displayLink: CADisplayLink?
    private var _gcdTimer: DispatchSourceTimer?
    private let _callback: () -> Void
    private let _mode: Mode
    private let _interval: TimeInterval

    public init(interval: TimeInterval, mode: Mode = .scheduledTimer, start: Bool = true, callback: @escaping () -> Void) {
        self._interval = interval
        self._mode = mode
        self._callback = callback
        if (start) { self.start() }
    }

    public var interval: TimeInterval {
        self._interval
    }

    public var mode: ScheduledTimer.Mode {
        self._mode
    }

    public func start() {
        self.stop()
        switch self._mode {
        case .scheduledTimer:
            self._timer = Timer.scheduledTimer(withTimeInterval: self._interval, repeats: true) { _ in
                self._callback()
            }
        case .displayTimer:
            let link: CADisplayLink = CADisplayLink(target: self, selector: #selector(onDisplayLinkTick))
            link.preferredFramesPerSecond = ScheduledTimer.approximateFPS(for: self._interval)
            link.add(to: .main, forMode: .common)
            self._displayLink = link
        case .dispatchTimer:
            let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
            let nanoseconds: UInt64 = UInt64(self._interval * 1_000_000_000)
            timer.schedule(deadline: .now() + self._interval, repeating: .nanoseconds(Int(nanoseconds)))
            timer.setEventHandler { [weak self] in
                self?._callback()
            }
            timer.resume()
            self._gcdTimer = timer
        }
    }

    public func stop() {
        self._timer?.invalidate()
        self._timer = nil
        self._displayLink?.invalidate()
        self._displayLink = nil
        self._gcdTimer?.cancel()
        self._gcdTimer = nil
    }

    @objc private func onDisplayLinkTick() {
        self._callback()
    }

    deinit {
        stop()
    }

    private static func approximateFPS(for interval: TimeInterval) -> Int {
        let maxFPS: Int = 120  // newer iPhones can go above 60Hz
        let fps: Int = Int(round(1.0 / interval))
        return max(1, min(maxFPS, fps))
    }
}
