import XCTest
import NothingProtocolTestKit

/// Idiomatic wrapper: one XCTest assertion per check from `runChecks()`.
/// Runs in Xcode and via `swift test` on CI (which has the XCTest toolchain).
final class RunChecksTests: XCTestCase {
    func testAllChecks() {
        for check in runChecks() {
            XCTAssertTrue(check.passed, "\(check.name): \(check.detail)")
        }
    }
}
