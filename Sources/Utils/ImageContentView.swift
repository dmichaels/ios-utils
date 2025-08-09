import SwiftUI
import Utils

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

        init(hideStatusBar: Bool = false, hideToolBar: Bool = false, ignoreSafeArea: Bool = false) {
            self.hideStatusBar = hideStatusBar
            self.hideToolBar = hideToolBar
            self.ignoreSafeArea = ignoreSafeArea
        }

        public func updateImage()      { self.versionImage += 1 }
        public func updateSettings()   { self.versionSettings += 1 }
        public func showSettingsView() { self.versionSettingsView += 1 }

        @Published internal private(set) var versionImage: Int = 0
        @Published internal private(set) var versionSettings: Int = 0
        @Published internal private(set) var versionSettingsView: Int = 0

        internal static let Defaults: Config = Config()
    }

    public protocol Viewable
    {
        init(_ config: ImageContentView.Config)
        var  image: CGImage { get }
        func update(viewSize: CGSize)
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
                    private var imageView: ImageContentView.Viewable
    @State          private var image: CGImage                   = DummyImage.instance
    @State          private var imageAngle: Angle                = Angle.zero
    @State          private var containerSize: CGSize            = CGSize.zero
    @State          private var containerBackground: Color?      = Color.yellow
    @StateObject    private var orientation: OrientationObserver = OrientationObserver()
    @State          private var showSettingsView: Bool           = false
    @State          private var hideStatusBar: Bool
    @State          private var hideToolBar: Bool
    @State          private var ignoreSafeArea: Bool

    public init(config: Config, imageView: Viewable, settingsView: SettingsViewable, toolBarViews: ToolBarViewables) {
        self.config = config
        self.imageView = imageView
        self.settingsView = settingsView
        self.toolBarViews = toolBarViews
        self.hideStatusBar = config.hideStatusBar
        self.hideToolBar = config.hideToolBar
        self.ignoreSafeArea = config.ignoreSafeArea
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { containerGeometry in ZStack {
                containerBackground ?? Color.green // Important trickery here
                Image(decorative: self.image, scale: 1.0)
                    .resizable().frame(width: CGFloat(image.width), height: CGFloat(image.height))
                    .position(x: containerGeometry.size.width / 2, y: containerGeometry.size.height / 2)
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
                .onAppear                                      { self.updateImage(geometry: containerGeometry) }
                .onChange(of: containerGeometry.size)          { self.updateImage(geometry: containerGeometry) }
                .onChange(of: self.config.versionSettings)     { self.updateSettings() }
                .onChange(of: self.config.versionSettingsView) { self.showSettingsView = true }
                .onChange(of: self.config.versionImage)        { self.image = self.imageView.image }
                .navigationDestination(isPresented: $showSettingsView) { AnyView(self.settingsView) }
            }
            .safeArea(ignore: self.ignoreSafeArea)
            .toolbar {
                //
                // This was a bit tricky; toolbars are treated a little specially/specifically by SwiftUI.
                //
                if (!self.hideToolBar && !self.ignoreSafeArea && (toolBarViews.count > 0)) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        toolBarViews[0]
                    }
                    if (toolBarViews.count > 2) {
                        ToolbarItem(placement: .navigation) {
                            ForEach(1..<(toolBarViews.count - 1), id: \.self) { i in
                                toolBarViews[i]
                            }
                        }
                    }
                    if (toolBarViews.count > 1) {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            toolBarViews[toolBarViews.count - 1]
                        }
                    }
                }
            }
        }
        .statusBar(hidden: self.hideStatusBar)
        .onAppear    { self.orientation.register(self.updateOrientation) }
        .onDisappear { self.orientation.deregister() }
    }

    private func updateImage(geometry: GeometryProxy) {
        self.containerSize = geometry.size
        self.imageView.update(viewSize: self.containerSize)
        self.image = self.imageView.image
    }

    private func updateOrientation(_ current: UIDeviceOrientation, _ previous: UIDeviceOrientation) {
        self.imageAngle = self.orientation.rotationAngle()
    }

    private func normalizePoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x - ((self.containerSize.width  - CGFloat(self.image.width))  / 2),
                       y: point.y - ((self.containerSize.height - CGFloat(self.image.height)) / 2))
    }

    private func ignorePoint(_ normalizedPoint: CGPoint) -> Bool {
        return (normalizedPoint.x < 0) || (normalizedPoint.x >= CGFloat(self.image.width))
            || (normalizedPoint.y < 0) || (normalizedPoint.y >= CGFloat(self.image.height))
    }

    private func updateSettings() {
        self.hideStatusBar = self.config.hideStatusBar
        self.hideToolBar = self.config.hideToolBar
        self.ignoreSafeArea = self.config.ignoreSafeArea
    }
}

extension View {
    @ViewBuilder
    internal func safeArea(ignore: Bool) -> some View {
        if (ignore) { self.ignoresSafeArea() } else { self }
    }
}

extension ImageContentView.Viewable {
    public var  image: CGImage { DummyImage.instance }
    public func update(viewSize: CGSize) {}
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
}
