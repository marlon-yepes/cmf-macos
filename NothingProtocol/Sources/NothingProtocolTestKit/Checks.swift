import NothingProtocol

/// The single source of test cases for the codec. Returns one `CheckResult` per
/// assertion; runners (the `verify` executable and XCTest) iterate the list.
public func runChecks() -> [CheckResult] {
    var results: [CheckResult] = []
    results.append(contentsOf: crcChecks())
    results.append(contentsOf: commandChecks())
    results.append(contentsOf: encoderChecks())
    return results
}

/// Hex dump helper for failure detail messages.
func hex(_ bytes: [UInt8]) -> String {
    "[" + bytes.map { String(format: "0x%02X", $0) }.joined(separator: ", ") + "]"
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

// MARK: - Encoder
// Golden frames computed by an independent CRC-16/MODBUS implementation.

private func encoderChecks() -> [CheckResult] {
    let getBattery = PacketEncoder.encode(command: .GET_BATTERY)
    let expectedGetBattery: [UInt8] = [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x07, 0x2C, 0xDD]

    let setLatency = PacketEncoder.encode(command: .SET_LATENCY, payload: [0x01])
    let expectedSetLatency: [UInt8] = [0x55, 0x60, 0x01, 0x40, 0xF0, 0x01, 0x00, 0x40, 0x01, 0x60, 0x62]

    return [
        CheckResult("encode(GET_BATTERY) == golden frame",
                    getBattery == expectedGetBattery,
                    "got \(hex(getBattery))"),
        CheckResult("encode(SET_LATENCY, [0x01]) == golden frame",
                    setLatency == expectedSetLatency,
                    "got \(hex(setLatency))"),
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
