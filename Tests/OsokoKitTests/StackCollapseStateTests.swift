import XCTest
import SwiftUI
@testable import OsokoKit

@MainActor
final class StackCollapseStateTests: XCTestCase {
    func testExpandAndCollapseTransitions() async {
        let state = StackCollapseState.shared

        state.expand()
        XCTAssertFalse(state.isCollapsed)

        state.collapse()
        XCTAssertTrue(state.isCollapsed)

        state.expand()
        XCTAssertFalse(state.isCollapsed)
    }

    func testHoverCancelsCollapse() async {
        let state = StackCollapseState.shared

        state.userHoverChanged(isHovering: true)
        XCTAssertTrue(state.isHovering)
        XCTAssertFalse(state.isCollapsed)

        // Attempting to collapse while user is hovering must be blocked
        state.collapse()
        XCTAssertFalse(state.isCollapsed)

        state.userHoverChanged(isHovering: false)
        XCTAssertFalse(state.isHovering)
    }
}
