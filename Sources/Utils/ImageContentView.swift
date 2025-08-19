import SwiftUI

// Example (with help from ChatGPT) relevant to simplifying ios-lifegame setup 2027-07-31 ...
// Went through lots of iterations; this is the simplest we came up with; lots of subtleties.
//
public struct ImageContentView: View
{
    public class Config: ObservableObject, @unchecked Sendable
    {
        public var hideStatusBar: Bool  = false
        public var hideToolBar: Bool    = false
        public var ignoreSafeArea: Bool = false
        public var background: Colour   = Colour.black
        public var imageView: ImageViewable? = nil

        public init(hideStatusBar: Bool = false, hideToolBar: Bool = false,
                    ignoreSafeArea: Bool = false, background: Colour? = nil) {
            self.hideStatusBar = hideStatusBar
            self.hideToolBar = hideToolBar
            self.ignoreSafeArea = ignoreSafeArea
            self.background = background ?? Colour.black
        }

        public func updateImage()      { self.watchImage += 1 }
        public func applySettings()    { self.watchSettings += 1 }
        public func showSettingsView() { self.watchSettingsView += 1 }

        @Published internal private(set) var watchImage: Int = 0
        @Published internal private(set) var watchSettings: Int = 0
        @Published internal private(set) var watchSettingsView: Int = 0

        public static let Defaults: Config = Config()
    }

    public protocol ImageViewable
    {
        var  image: CGImage { get }
        var  size: CGSize { get }
        var  scale: CGFloat { get }
        func update(viewSize: CGSize)
        func setupSettings()
        func applySettings()
        func onTap(_ point: CGPoint)
        func onLongTap(_ point: CGPoint)
        func onDoubleTap(_ point: CGPoint?)
        func onDrag(_ point: CGPoint)
        func onDragEnd(_ point: CGPoint)
        var  onDragStrict: Bool { get }
        func onZoom(_ zoomFactor: CGFloat)
        func onZoomEnd(_ zoomFactor: CGFloat)
        func onSwipeLeft()
        func onSwipeRight()
        var  viewPoints: Bool { get }
    }

    public protocol SettingsViewable: View {}

    public typealias ToolBarItemBuilder = (ImageContentView.Config) -> AnyView

    public static func ToolBarItem(@ViewBuilder _ make: @escaping (Config) -> some View) -> ToolBarItemBuilder {
        { config in AnyView(make(config)) }
    }

    public static func ToolBarViewable(_ config: Config, _ toolBarViews: ToolBarItemBuilder...) -> ToolBarViewables {
        return toolBarViews.map { item in item(config) }
    }

    public static func ToolBarViewable(_ config: Config, _ toolBarViews: [ToolBarItemBuilder]) -> ToolBarViewables {
        return toolBarViews.map { item in item(config) }
    }

    public typealias ToolBarViewables = [AnyView]

    @ObservedObject private var config: ImageContentView.Config
                    private var settingsView: any SettingsViewable
                    private var toolBarViews: ToolBarViewables
                    private var imageView: ImageContentView.ImageViewable
    @State          private var image: CGImage                   = DefaultImage.instance
    @State          private var imageAngle: Angle                = Angle.zero
    @State          private var viewSize: CGSize                 = CGSize.zero
    @StateObject    private var orientation: OrientationObserver = OrientationObserver()
    @State          private var showSettingsView: Bool           = false
    @State          private var hideStatusBar: Bool
    @State          private var hideToolBar: Bool
    @State          private var ignoreSafeArea: Bool
    @State          private var background: Color

    public init(config: Config, imageView: ImageViewable, settingsView: any SettingsViewable, toolBarViews: ToolBarViewables) {
        config.imageView = imageView
        self.config = config
        self.imageView = imageView
        self.settingsView = settingsView
        self.toolBarViews = toolBarViews
        self.background = config.background.color
        self.hideStatusBar = config.hideStatusBar
        self.hideToolBar = config.hideToolBar
        self.ignoreSafeArea = config.ignoreSafeArea
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { viewGeometry in ZStack {
                self.background // Important trickery here
                Image(decorative: self.image, scale: self.imageView.scale)
                    .resizable().frame(width: self.imageView.size.width, height: self.imageView.size.height)
                    .position(x: viewGeometry.size.width / 2, y: viewGeometry.size.height / 2)
                    .rotationEffect(self.imageAngle)
                }
                .onSmartGesture(
                    normalizePoint: self.normalizePoint,
                    ignorePoint:    self.ignorePoint,
                    onTap:          { imagePoint in self.imageView.onTap(imagePoint) },
                    onLongTap:      { imagePoint in self.imageView.onLongTap(imagePoint) },
                    onDoubleTap:    { imagePoint in self.imageView.onDoubleTap(imagePoint) },
                    onDrag:         { imagePoint in self.imageView.onDrag(imagePoint) },
                    onDragEnd:      { imagePoint in self.imageView.onDragEnd(imagePoint) },
                    onDragStrict:   self.imageView.onDragStrict,
                    onZoom:         { zoomFactor in self.imageView.onZoom(zoomFactor) },
                    onZoomEnd:      { zoomFactor in self.imageView.onZoomEnd(zoomFactor) },
                    onSwipeLeft:    { self.imageView.onSwipeLeft() },
                    onSwipeRight:   { self.imageView.onSwipeRight() }
                )
                .onAppear                                    { self.updateImage(geometry: viewGeometry) }
                .onChange(of: viewGeometry.size)             { self.updateImage(geometry: viewGeometry) }
                .onChange(of: self.config.watchSettings)     { self.applySettings() }
                .onChange(of: self.config.watchSettingsView) { self.imageView.setupSettings() ; self.showSettingsView = true }
                .onChange(of: self.config.watchImage)        { self.image = self.imageView.image }
                .navigationDestination(isPresented: $showSettingsView) { AnyView(self.settingsView) }
            }
            .safeArea(ignore: self.ignoreSafeArea)
            .toolBarView(hidden: self.hideToolBar || self.ignoreSafeArea, self.toolBarViews)
        }
        .statusBar(hidden: self.hideStatusBar)
        .onAppear    { self.orientation.register(self.updateOrientation) }
        .onDisappear { self.orientation.deregister() }
    }

    private func updateImage(geometry: GeometryProxy) {
        self.viewSize = geometry.size
        self.imageView.update(viewSize: self.viewSize)
        self.image = self.imageView.image
    }

    private func updateOrientation(_ current: UIDeviceOrientation, _ previous: UIDeviceOrientation) {
        self.imageAngle = self.orientation.rotationAngle()
    }

    private func normalizePoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x - ((self.viewSize.width  - self.imageView.size.width)  / 2),
                       y: point.y - ((self.viewSize.height - self.imageView.size.height) / 2))
    }

    private func ignorePoint(_ normalizedPoint: CGPoint) -> Bool {
        guard !self.imageView.viewPoints else { return false }
        return (normalizedPoint.x < 0) || (normalizedPoint.x >= self.imageView.size.width)
            || (normalizedPoint.y < 0) || (normalizedPoint.y >= self.imageView.size.height)
    }

    private func applySettings() {
        self.hideStatusBar = self.config.hideStatusBar
        self.hideToolBar = self.config.hideToolBar
        self.ignoreSafeArea = self.config.ignoreSafeArea
        self.background = self.config.background.color
        self.imageView.applySettings()
    }
}

extension View {
    @ViewBuilder
    internal func safeArea(ignore: Bool) -> some View {
        if (ignore) { self.ignoresSafeArea() } else { self }
    }
    @ViewBuilder
    internal func toolBarView(hidden: Bool = false, _ toolBarViews: ImageContentView.ToolBarViewables) -> some View {
        self.toolbar {
            if (!hidden) {
                ToolbarItem(placement: .navigationBarLeading) {
                    toolBarViews[0]
                }
                if (toolBarViews.count > 2) {
                    ToolbarItem(placement: .principal) {
                        ForEach(1..<(toolBarViews.count - 1), id: \.self) { i in
                            toolBarViews[i]
                        }
                    }
                }
                if (toolBarViews.count > 1) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolBarViews.last!
                    }
                }
            }
        }
    }
}

extension ImageContentView.ImageViewable {
    public func setupSettings() {}
    public func applySettings() {}
    public func onTap(_ point: CGPoint) {}
    public func onLongTap(_ point: CGPoint) {}
    public func onDoubleTap(_ point: CGPoint?) {}
    public func onDrag(_ point: CGPoint) {}
    public func onDragEnd(_ point: CGPoint) {}
    public var  onDragStrict: Bool { false }
    public func onZoom(_ zoomFactor: CGFloat) {}
    public func onZoomEnd(_ zoomFactor: CGFloat) {}
    public func onSwipeLeft() {}
    public func onSwipeRight() {}
    public var  viewPoints: Bool { false }
}
