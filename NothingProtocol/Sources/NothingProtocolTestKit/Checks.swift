import NothingProtocol

/// The single source of test cases for the codec. Returns one `CheckResult` per
/// assertion; runners (the `verify` executable and XCTest) iterate the list.
public func runChecks() -> [CheckResult] {
    var results: [CheckResult] = []
    results.append(contentsOf: crcChecks())
    results.append(contentsOf: commandChecks())
    return results
}

// MARK: - Command & constants

private func commandChecks() -> [CheckResult] {
    return [
        CheckResult("Command.GET_BATTERY raw == 0x07C0",
                    Command.GET_BATTERY.rawValue == 0x07C0,
                    "got 0x\(String(Command.GET_BATTERY.rawValue, radix: 16))"),
        CheckResult("Command.GET_BATTERY.operationID == 0x07",
                    Command.GET_BATTERY.operationID == 0x07,
                    "got 0x\(String(Command.GET_BATTERY.operationID, radix: 16))"),
        CheckResult("Command.SET_LATENCY.operationID == 0x40",
                    Command.SET_LATENCY.operationID == 0x40,
                    "got 0x\(String(Command.SET_LATENCY.operationID, radix: 16))"),
        CheckResult("ProtocolConstants.magic == 0x55",
                    ProtocolConstants.magic == 0x55,
                    "got 0x\(String(ProtocolConstants.magic, radix: 16))"),
    ]
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
