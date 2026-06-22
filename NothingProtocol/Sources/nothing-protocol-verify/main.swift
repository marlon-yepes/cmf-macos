import Foundation
import NothingProtocolTestKit

let results = runChecks()
for result in results {
    let mark = result.passed ? "PASS " : "FAIL "
    let detail = result.detail.isEmpty ? "" : "  [\(result.detail)]"
    print(mark + result.name + detail)
}

let failed = results.filter { !$0.passed }
print("\n\(results.count - failed.count)/\(results.count) checks passed")
if !failed.isEmpty {
    exit(1)
}
