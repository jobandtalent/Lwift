public enum RenderPolicy {
    case possible
    case notPossible(RenderError)

    public enum RenderError {
        case viewNotReady
        case viewDeallocated
    }

    var canBeRendered: Bool {
        switch self {
        case .possible:
            return true
        case .notPossible:
            return false
        }
    }
}

public protocol StatefulView: class, CustomLogDescriptionConvertible {
    associatedtype State: ViewState
    // Never call it directly. Always call viewModel's `subscribe(from:)`. Some advantages:
    //
    // 1. We have "arrow consistency", always being rendered by viewModel's command, minimizing
    // view logic. View only decides when it's ready to subscribe, depending on its lifecycle.
    //
    // 2. Avoid rendering the view when not appropriate, such as when trying to render in a thread
    // different from the main one, when the view is not yet on the screen or trying to render the
    // very same state.
    func render(state: State)
    var renderPolicy: RenderPolicy { get }
}

public extension StatefulView where Self: UIViewController {
    var renderPolicy: RenderPolicy {
        return isViewLoaded ? .possible : .notPossible(.viewNotReady)
    }

    var logDescription: String {
        return title ?? String(describing: type(of: self))
    }
}

public extension StatefulView where Self: UIView {
    var renderPolicy: RenderPolicy {
        return superview != nil ? .possible : .notPossible(.viewNotReady)
    }

    var logDescription: String {
        return String(describing: type(of: self))
    }
}

// Stateful view wrapper used to make Swift type system help us
// to match the State between a view and their viewModel.
public class AnyStatefulView<T: ViewState>: StatefulView {
    private let _render: (T) -> Void
    private let _logDescription: () -> String
    private let _renderPolicy: () -> RenderPolicy
    let identifier: String

    public init<U: StatefulView>(_ statefulView: U) where U.State == T {
        _render = { [weak statefulView] state in
            statefulView?.render(state: state)
        }

        _logDescription = { [weak statefulView] in
            statefulView?.logDescription ?? "Deallocated view"
        }

        _renderPolicy = { [weak statefulView] in
            statefulView?.renderPolicy ?? .notPossible(.viewDeallocated)
        }

        identifier = String(describing: statefulView)
    }

    public func render(state: T) {
        guard renderPolicy.canBeRendered else {
            fatalError("""
            View is not ready to be rendered.
            This usually happens when trying to render a view controller that is not ready yet (viewDidLoad
            hasn't been called yet and outlets are not ready) or a view that is not on the screen yet. To avoid
            this problem, try using `viewModel.subscribe(from: self)` from the view layer when the view or
            view controller are ready to be rendered.
            """)
        }
        _render(state)
    }

    public var renderPolicy: RenderPolicy {
        return _renderPolicy()
    }

    public var logDescription: String {
        return _logDescription()
    }
}

extension AnyStatefulView: Hashable {
    public var hashValue: Int {
        return identifier.hashValue
    }

    public static func ==(lhs: AnyStatefulView, rhs: AnyStatefulView) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
