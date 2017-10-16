import XCTest
@testable import Lwift

class StoreTests: XCTestCase {
    private var currentStoreSubscription: StateSubscription<StoreDoubleState>!

    func testStoreReceivesCorrectInitialState() {
        let initialState = StoreDoubleState(text: "Initial state")
        let store = StoreDouble(initialState: initialState)
        XCTAssertEqual(store.state, initialState)
    }

    func testStoreSendsCurrentStateOnSubscription() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        var currentState: StoreDoubleState?
        currentStoreSubscription = store.subscribe {
            currentState = $0
        }
        XCTAssert(currentState == store.state)
    }

    func testStoreForwardsCorrectState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        var numberOfNotifyStateChangeCalls = 0
        currentStoreSubscription = store.subscribe { _ in
            numberOfNotifyStateChangeCalls += 1
        }

        store.write {
            store.state = StoreDoubleState(text: "Another state")
            store.state = StoreDoubleState(text: "Another different state")
        }

        XCTAssert(numberOfNotifyStateChangeCalls == 3)
    }

    func testStoreDoesNotForwardSameState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        var numberOfNotifyStateChangeCalls = 0
        currentStoreSubscription = store.subscribe { _ in
            numberOfNotifyStateChangeCalls += 1
        }

        store.write {
            store.state = StoreDoubleState(text: "Another state")
            store.state = StoreDoubleState(text: "Another state")
        }
        XCTAssertTrue(numberOfNotifyStateChangeCalls == 2)
    }

    func testUndoRecoversPreviousState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        store.write {
            store.state = StoreDoubleState(text: "first state")
            store.state = StoreDoubleState(text: "second state")
            store.undo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "first state"))
        store.write {
            store.undo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "Initial state"))
    }

    func testUndoMaintainsInitialState() {
        let initialState = StoreDoubleState(text: "Initial state")
        let store = StoreDouble(initialState: initialState)
        store.write {
            store.undo()
        }
        XCTAssertEqual(store.state, initialState)
    }

    func testRedoRecoversNextState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        store.write {
            store.state = StoreDoubleState(text: "first state")
            store.state = StoreDoubleState(text: "second state")
            store.undo()
            store.undo() // back to initial state
            store.redo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "first state"))
        store.write {
            store.redo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "second state"))
    }

    func testRedoMaintainsLastState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        store.write {
            store.state = StoreDoubleState(text: "first state")
            store.redo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "first state"))
    }

    func testRedoClearsAfterSettingNewState() {
        let store = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        store.write {
            store.state = StoreDoubleState(text: "first state")
            store.state = StoreDoubleState(text: "second state")
            store.undo()
            store.state = StoreDoubleState(text: "third state")
            store.redo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "third state"))
        store.write {
            store.undo()
        }
        XCTAssertEqual(store.state, StoreDoubleState(text: "first state"))
    }

    func testStoreForwardsStateToOtherStoresCorrectly() {
        let sut = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        let firstStore = AnotherStoreDouble(initialState: AnotherStoreDoubleState(number: 5))
        let secondStore = AnotherStoreDouble(initialState: AnotherStoreDoubleState(number: 10))
        var firstState, secondState: AnotherStoreDoubleState?
        var firstNumberOfSubscriptionCalls = 0, secondNumberOfSubscriptionCalls = 0
        sut.subscribe(to: firstStore) { firstState = $0; firstNumberOfSubscriptionCalls += 1 }
        sut.subscribe(to: secondStore) { secondState = $0; secondNumberOfSubscriptionCalls += 1 }
        XCTAssert(firstState == firstStore.state && firstNumberOfSubscriptionCalls == 1)
        XCTAssert(secondState == secondStore.state && secondNumberOfSubscriptionCalls == 1);
        XCTAssert(sut.state == StoreDoubleState(text: "Initial state"))

        let anotherState = AnotherStoreDoubleState(number: 80)
        firstStore.write {
            firstStore.state = anotherState
        }

        XCTAssert(firstState == anotherState && firstNumberOfSubscriptionCalls == 2)
        firstStore.write {
            firstStore.state = anotherState
        }
        XCTAssert(firstNumberOfSubscriptionCalls == 2)
    }

    func testStoreDoesNotReceiveOtherStoreUpdatesAfterUnsubscribe() {
        let sut = StoreDouble(initialState: StoreDoubleState(text: "Initial state"))
        let initialStoreState = AnotherStoreDoubleState(number: 5)
        let store = AnotherStoreDouble(initialState: initialStoreState)
        var state: AnotherStoreDoubleState?
        var numberOfSubscriptionCalls = 0
        sut.subscribe(to: store) { state = $0; numberOfSubscriptionCalls += 1 }
        sut.unsubscribe(from: store)

        let anotherState = AnotherStoreDoubleState(number: 80)
        store.write {
            store.state = anotherState
        }
        XCTAssert(state == initialStoreState && numberOfSubscriptionCalls == 1)
    }
}
