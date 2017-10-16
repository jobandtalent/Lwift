public class StateSubscription<State> {
    private(set) var block: ((State) -> Void)?

    init(_ block: @escaping (State) -> Void) {
        self.block = block
    }

    func fire(_ state: State) {
        block?(state)
    }

    func stop() {
        block = nil
    }

    deinit {
        stop()
    }
}
