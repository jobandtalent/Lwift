open class ViewModel<State: ViewState>: Store<State> {
    private var views = Set<AnyStatefulView<State>>()

    // This should be protected and changed only by subclasses.
    // Never read it directly from views, always call `subscribe(from:)`.
    public override var state: State {
        didSet(oldState) {
            views.forEach {
                stateDidChange(oldState: oldState, newState: state, view: $0)
            }
        }
    }

    public func subscribe<V: StatefulView>(from view: V) where V.State == State {
        let anyView = AnyStatefulView(view)
        if views.insert(anyView).inserted {
            stateDidChange(oldState: state, newState: state, view: anyView, force: true)
        } else {
            #if DEBUG
                fatalError("Trying to subscribe from an already subscribed view.")
            #endif
        }
    }

    public func unsubscribe<V: StatefulView>(from view: V) where V.State == State {
        if views.remove(AnyStatefulView(view)) == nil {
            #if DEBUG
                fatalError("Trying to unsubscribe from a not subscribed view.")
            #endif
        }
    }

    private func stateDidChange(oldState: State, newState: State, view: AnyStatefulView<State>, force: Bool = false) {
        switch view.renderPolicy {
        case .possible:
            handlePossibleRender(newState: newState, oldState: oldState, view: view, force: force)
        case .notPossible(let renderError):
            handleNotPossibleRender(error: renderError, view: view)
        }
    }

    private func handlePossibleRender(newState: State, oldState: State, view: AnyStatefulView<State>, force: Bool) {
        let viewLogDescription = view.logDescription

        if !force && newState == oldState {
            debugLog("[\(viewLogDescription)] Skip rendering with the same state: \(newState.logDescription)")
            return
        }

        debugLog("[\(viewLogDescription)] Render with state: \(newState.logDescription)")

        let renderBlock = {
            view.render(state: newState)
        }

        if Thread.isMainThread {
            renderBlock()
        } else {
            DispatchQueue.main.async(execute: renderBlock)
        }
    }

    private func handleNotPossibleRender(error: RenderPolicy.RenderError, view: AnyStatefulView<State>) {
        switch error {
        case .viewNotReady:
            fatalError("[\(view.logDescription)] Render error: view not ready to be rendered")
        case .viewDeallocated:
            debugLog("[\(view.identifier)] Render error: view deallocated")
            views.remove(view)
        }
    }

    private func debugLog(_ str: @autoclosure () -> String) {
        #if DEBUG
            print(str())
        #endif
    }
}
