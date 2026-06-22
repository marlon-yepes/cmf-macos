import NothingProtocol

/// The single source of test cases for the codec. Returns one `CheckResult` per
/// assertion; runners (the `verify` executable and XCTest) iterate the list.
public func runChecks() -> [CheckResult] {
    var results: [CheckResult] = []
    results.append(contentsOf: crcChecks())
    return results
}

// MARK: - CRC16

private func crcChecks() -> [CheckResult] {
    // Golden value frozen from the app's CRC16 implementation.
    let crc = crc16([0x55, 0x60, 0x01])
    return [
        CheckResult("crc16/modbus [0x55,0x60,0x01] == 0x1088",
                    crc == 0x1088,
                    "got 0x\(String(crc, radix: 16))"),
    ]
}
