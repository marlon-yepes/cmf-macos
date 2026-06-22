/// One assertion's outcome. Both the `verify` executable and the XCTest target
/// consume `runChecks()`, so the test cases live in exactly one place.
public struct CheckResult {
    public let name: String
    public let passed: Bool
    public let detail: String

    public init(_ name: String, _ passed: Bool, _ detail: String = "") {
        self.name = name
        self.passed = passed
        self.detail = detail
    }
}
