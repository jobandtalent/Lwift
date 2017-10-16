open class Store<State: StoreState> {
    private var subscriptions = NSHashTable<StateSubscription<State>>.weakObjects()
    private var otherStoresSubscriptions = [String: AnyObject]()
    private lazy var stateTransactionQueue = DispatchQueue(label: "com.jobandtalent.\(type(of: self)).StateTransactionQueue")

    // This should be protected and changed only by subclasses.
    public var state: State {
        didSet(oldState) {
            if #available(iOS 10.0, *) {
                dispatchPrecondition(condition: .onQueue(stateTransactionQueue))
            }

            stateDidChange(oldState: oldState, newState: state)
        }
    }

    open var storeIdentifier: String {
        return String(describing: self)
    }

    private var isApplyingUndoOrRedo = false
    private var undoStack = [UndoRedoState<State>]()
    private var redoStack = [UndoRedoState<State>]()

    public init(initialState: State) {
        state = initialState
    }

    public func write(_ transaction: () -> Void) {
        stateTransactionQueue.sync(execute: transaction)
    }

    // Helper method to subscribe to other stores that automatically retains the subscription tokens
    // so children stores can easily subscribe to other store changes without hassle.
    public func subscribe<T>(to store: Store<T>, block: @escaping (T) -> Void) {
        if otherStoresSubscriptions[store.storeIdentifier] != nil {
            #if DEBUG
                fatalError("Trying to subscribe to an already subscribed store.")
            #endif
        }

        otherStoresSubscriptions[store.storeIdentifier] = store.subscribe(block)
    }

    public func unsubscribe<T>(from store: Store<T>) {
        if otherStoresSubscriptions[store.storeIdentifier] == nil {
            #if DEBUG
                fatalError("Trying to unsubscribe from a not subscribed store.")
            #endif
        }

        otherStoresSubscriptions[store.storeIdentifier] = nil
    }

    public func subscribe(_ block: @escaping (State) -> Void) -> StateSubscription<State> {
        let subscription = StateSubscription(block)
        subscriptions.add(subscription)
        subscription.fire(state)
        return subscription
    }

    private func stateDidChange(oldState: State, newState: State) {
        guard oldState != newState else {
            debugLog("[\(storeLogDescription())] Skip forwarding same state: \(newState.logDescription)")
            return
        }

        if !isApplyingUndoOrRedo {
            let undoState = UndoRedoState(oldState: oldState, newState: newState)
            undoStack.append(undoState)
            redoStack = []
        }

        debugLog("[\(storeLogDescription())] State change: \(newState.logDescription)")
        subscriptions.allObjects.forEach {
            $0.fire(state)
        }
    }

    func undo() {
        debugLog("[\(storeLogDescription())] Undo state")
        guard let undoRedoState = self.undoStack.popLast() else { return }
        applyUndoRedoState(undoRedoState)
        redoStack.append(undoRedoState.flip())
    }

    func redo() {
        debugLog("[\(storeLogDescription())] Redo state")
        guard let undoRedoState = self.redoStack.popLast() else { return }
        applyUndoRedoState(undoRedoState)
        undoStack.append(undoRedoState.flip())
    }

    private func applyUndoRedoState(_ undoRedoState: UndoRedoState<State>) {
        isApplyingUndoOrRedo = true
        state = undoRedoState.oldState
        isApplyingUndoOrRedo = false
    }

    private func storeLogDescription() -> String {
        return String(describing: type(of: self))
    }

    private func debugLog(_ str: @autoclosure () -> String) {
        #if DEBUG
            print(str())
        #endif
    }
}

private struct UndoRedoState<T: StoreState> {
    let oldState: T
    let newState: T

    func flip() -> UndoRedoState<T> {
        return UndoRedoState(oldState: newState, newState: oldState)
    }
}
