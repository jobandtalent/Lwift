import XCTest
@testable import Lwift

class StatefulViewTests: XCTestCase {
    func testViewReceivesRenderMethod() {
        let viewSpy = ViewSpy()
        let statefulView = AnyStatefulView(viewSpy)
        statefulView.render(state: ViewSpyState(text: "Text"))
        XCTAssert(viewSpy.numberOfRenderCalls == 1)
    }

    func testRenderPolicyMethodCalledInView() {
        let viewSpy = ViewSpy()
        let statefulView = AnyStatefulView(viewSpy)
        _ = statefulView.renderPolicy
        XCTAssertTrue(viewSpy.renderPolicyCalled)
    }

    func testLogDescriptionMethodCalledInView() {
        let viewSpy = ViewSpy()
        let statefulView = AnyStatefulView(viewSpy)
        _ = statefulView.logDescription
        XCTAssertTrue(viewSpy.logDescriptionCalled)
    }

    func testViewControllerCannotBeRenderedWhenViewDeallocated() {
        var viewSpy: ViewSpy? = ViewSpy()
        weak var weakView = viewSpy
        let statefulView = AnyStatefulView(viewSpy!)
        viewSpy = nil
        XCTAssertNil(weakView)
        XCTAssert(statefulView.renderPolicy == .notPossible(.viewDeallocated))
    }

    func testViewControllerCanBeRenderedAppropriatelyWhenViewLoaded() {
        let viewController = RealViewController()
        XCTAssert(viewController.renderPolicy == .notPossible(.viewNotReady))
        _ = viewController.view
        XCTAssert(viewController.renderPolicy == .possible)
    }

    func testViewCanBeRenderedAppropriatelyWhenAddedToSuperview() {
        let view = RealView()
        XCTAssert(view.renderPolicy == .notPossible(.viewNotReady))
        let parentView = UIView()
        parentView.addSubview(view)
        XCTAssert(view.renderPolicy == .possible)
    }
}

extension RenderPolicy: Equatable {
    public static func ==(lhs: RenderPolicy, rhs: RenderPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.possible, .possible):
            return true
        case (.notPossible(let lhsRenderError), .notPossible(let rhsRenderError)):
            return lhsRenderError == rhsRenderError
        default:
            return false
        }
    }
}

extension RenderPolicy.RenderError {
    public static func ==(lhs: RenderPolicy.RenderError, rhs: RenderPolicy.RenderError) -> Bool {
        switch (lhs, rhs) {
        case (.viewNotReady, .viewNotReady):
            return true
        case (.viewDeallocated, .viewDeallocated):
            return true
        default:
            return false
        }
    }
}
