import XCTest
import SwiftUI
@testable import Lumen

// MARK: - LumenColors Tests
// Guards the semantic palette: each token must equal the exact hex it replaced,
// so the token layer stays a behavior-preserving source of truth.

final class LumenColorsTests: XCTestCase {

    func testAccentMatchesSourceHex() {
        XCTAssertEqual(Color.lumenAccent, Color(hex: "#C49A6C"))
    }

    func testBackgroundMatchesSourceHex() {
        XCTAssertEqual(Color.lumenBackground, Color(hex: "#0E0819"))
    }

    func testSuccessMatchesSourceHex() {
        XCTAssertEqual(Color.lumenSuccess, Color(hex: "#6FDBA8"))
    }
}
