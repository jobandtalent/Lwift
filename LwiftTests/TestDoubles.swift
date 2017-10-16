@testable import Lwift

struct ViewSpyState: ViewState {
    let text: String

    init(text: String) {
        self.text = text
    }

    static func ==(lhs: ViewSpyState, rhs: ViewSpyState) -> Bool {
        return lhs.text == rhs.text
    }
}

class ViewSpy: StatefulView {
    private(set) var numberOfRenderCalls = 0
    private(set) var state: ViewSpyState!
    private(set) var renderPolicyCalled = false
    private(set) var logDescriptionCalled = false

    func render(state: ViewSpyState) {
        self.state = state
        numberOfRenderCalls += 1
    }

    var renderPolicy: RenderPolicy {
        renderPolicyCalled = true
        return .possible
    }

    var logDescription: String {
        logDescriptionCalled = true
        return String(describing: self)
    }
}

class AnotherViewSpy: ViewSpy {}

class ViewModelDouble: ViewModel<ViewSpyState> {}

struct AnotherViewModelDoubleState: ViewState {
    let number: Int

    static func ==(lhs: AnotherViewModelDoubleState, rhs: AnotherViewModelDoubleState) -> Bool {
        return lhs.number == rhs.number
    }
}

class AnotherViewModelDouble: ViewModel<AnotherViewModelDoubleState> {}

class RealView: UIView, StatefulView {
    func render(state: ViewSpyState) {}
}

class RealViewController: UIViewController, StatefulView {
    func render(state: ViewSpyState) {}
}

struct StoreDoubleState: StoreState {
    let text: String

    static func ==(lhs: StoreDoubleState, rhs: StoreDoubleState) -> Bool {
        return lhs.text == rhs.text
    }
}

struct AnotherStoreDoubleState: StoreState {
    let number: Int

    static func ==(lhs: AnotherStoreDoubleState, rhs: AnotherStoreDoubleState) -> Bool {
        return lhs.number == rhs.number
    }
}

class StoreDouble: Store<StoreDoubleState> {}
class AnotherStoreDouble: Store<AnotherStoreDoubleState> {
    override var storeIdentifier: String {
        return String(state.number)
    }
}

struct StoreSubscriptionState: StoreState {}

class StoreSubscriptionSpy: StateSubscription<StoreSubscriptionState> {
    var stopCalledBlock: (() -> Void)?

    override func stop() {
        stopCalledBlock?()
    }
}
