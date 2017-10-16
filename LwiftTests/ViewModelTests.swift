import XCTest
@testable import Lwift

class ViewModelTests: XCTestCase {
    func testRenderMethodCalledWhenSubscribed() {
        let view1 = ViewSpy()
        let view2 = AnotherViewSpy()
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2)
        XCTAssert(view1.numberOfRenderCalls == 1)
        XCTAssert(view2.numberOfRenderCalls == 1)
        XCTAssert(viewModel.state == view1.state)
        XCTAssert(viewModel.state == view2.state)
    }

    func testRenderMethodCalledTwiceForInitialAndStateChange() {
        let view1 = ViewSpy()
        let view2 = AnotherViewSpy()
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2)
        viewModel.write {
            viewModel.state = ViewSpyState(text: "State")
        }
        XCTAssert(view1.numberOfRenderCalls == 2)
        XCTAssert(view2.numberOfRenderCalls == 2)
        XCTAssert(viewModel.state == view1.state)
        XCTAssert(viewModel.state == view2.state)
    }

    func testRenderMethodNotCalledWhenSetSameState() {
        let view1 = ViewSpy()
        let view2 = AnotherViewSpy()
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2)
        viewModel.write {
            viewModel.state = ViewSpyState(text: "InitialState")
        }
        XCTAssert(view1.numberOfRenderCalls == 1)
        XCTAssert(view2.numberOfRenderCalls == 1)
        XCTAssert(viewModel.state == view1.state)
        XCTAssert(viewModel.state == view2.state)
    }

    func testRenderMethodNotCalledAfterUnsubscribed() {
        let view1 = ViewSpy()
        let view2 = AnotherViewSpy()
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2)
        viewModel.unsubscribe(from: view1)
        viewModel.unsubscribe(from: view2)
        viewModel.write {
            viewModel.state = ViewSpyState(text: "State")
        }
        XCTAssert(view1.numberOfRenderCalls == 1)
        XCTAssert(view2.numberOfRenderCalls == 1)
    }

    func testRenderMethodCalledWithLatestViewModelStateAfterSubscribed() {
        let view1 = ViewSpy()
        let view2 = AnotherViewSpy()
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.write {
            viewModel.state = ViewSpyState(text: "State")
        }
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2)
        XCTAssert(view1.numberOfRenderCalls == 1)
        XCTAssert(view2.numberOfRenderCalls == 1)
        XCTAssert(viewModel.state == view1.state)
        XCTAssert(viewModel.state == view2.state)
    }

    func testViewModelDoesNotRetainViews() {
        var view1: ViewSpy? = ViewSpy()
        var view2: ViewSpy? = AnotherViewSpy()
        weak var weakView1 = view1
        weak var weakView2 = view2
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1!)
        viewModel.subscribe(from: view2!)
        view1 = nil
        view2 = nil
        XCTAssertNil(weakView1)
        XCTAssertNil(weakView2)
    }

    func testViewModelForwardsStateChangesToRemainingViewsWhenSomeViewIsDeallocated() {
        let view1 = ViewSpy()
        var view2: AnotherViewSpy? = AnotherViewSpy()
        weak var weakView2 = view2
        let viewModel = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        viewModel.subscribe(from: view1)
        viewModel.subscribe(from: view2!)
        view2 = nil
        viewModel.write {
            viewModel.state = ViewSpyState(text: "State")
        }
        XCTAssertNil(weakView2)
        XCTAssert(view1.numberOfRenderCalls == 2)
        XCTAssert(viewModel.state == view1.state)
    }

    func testViewModelForwardsStateToViewAndOtherViewModelsCorrectly() {
        let sut = ViewModelDouble(initialState: ViewSpyState(text: "InitialState"))
        let viewModel = AnotherViewModelDouble(initialState: AnotherViewModelDoubleState(number: 5))
        let view = ViewSpy()
        sut += view

        var state: AnotherViewModelDoubleState?
        var numberOfSubscriptionCalls = 0
        sut.subscribe(to: viewModel) {
            state = $0
            numberOfSubscriptionCalls += 1
        }

        XCTAssert(view.numberOfRenderCalls == 1)
        XCTAssert(state == viewModel.state)
        XCTAssert(numberOfSubscriptionCalls == 1)

        let newAnotherViewModelState = AnotherViewModelDoubleState(number: 8)
        viewModel.write {
            viewModel.state = newAnotherViewModelState
        }

        XCTAssert(view.numberOfRenderCalls == 1)
        XCTAssert(state == newAnotherViewModelState)
        XCTAssert(numberOfSubscriptionCalls == 2)

        sut.write {
            sut.state = ViewSpyState(text: "Another state")
        }

        XCTAssert(view.numberOfRenderCalls == 2)
        XCTAssert(state == newAnotherViewModelState)

        viewModel.write {
            viewModel.state = newAnotherViewModelState
        }

        XCTAssert(numberOfSubscriptionCalls == 2)
    }
}
