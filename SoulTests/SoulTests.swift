import XCTest
@testable import Soul

final class SoulTests: XCTestCase {

    func testProjectStatusDisplayNames() {
        XCTAssertEqual(ProjectStatus.active.displayName, "Active")
        XCTAssertEqual(ProjectStatus.paused.displayName, "Paused")
        XCTAssertEqual(ProjectStatus.completed.displayName, "Completed")
    }

    func testStringIsBlank() {
        XCTAssertTrue("".isBlank)
        XCTAssertTrue("   ".isBlank)
        XCTAssertFalse("hello".isBlank)
    }

    func testStringTruncated() {
        let long = "Hello, this is a long string"
        XCTAssertEqual(long.truncated(to: 5), "Hello...")
        XCTAssertEqual("Hi".truncated(to: 10), "Hi")
    }

    func testAvatarInitials() {
        let view = AvatarView(url: nil, size: 40, name: "John Doe")
        // Initials are derived from name
        // Just validate the view initializes without crash
        XCTAssertNotNil(view)
    }
}
