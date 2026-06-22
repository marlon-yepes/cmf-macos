import NothingProtocol

/// The single source of test cases for the codec. Returns one `CheckResult` per
/// assertion; runners (the `verify` executable and XCTest) iterate the list.
public func runChecks() -> [CheckResult] {
    var results: [CheckResult] = []
    results.append(contentsOf: crcChecks())
    results.append(contentsOf: commandChecks())
    results.append(contentsOf: encoderChecks())
    results.append(contentsOf: decoderChecks())
    results.append(contentsOf: payloadDecoderChecks())
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

// MARK: - Decoder

private func decoderChecks() -> [CheckResult] {
    var checks: [CheckResult] = []

    // Round-trip: encode a frame with payload, then decode it back.
    let frame = PacketEncoder.encode(command: .SET_LATENCY, payload: [0x01])
    if let packet = PacketDecoder.decode(frame) {
        checks.append(CheckResult("decode round-trip: command == 0x40F0",
                                  packet.command == 0x40F0,
                                  "got 0x\(String(packet.command, radix: 16))"))
        checks.append(CheckResult("decode round-trip: operationID == 0x40",
                                  packet.operationID == 0x40,
                                  "got 0x\(String(packet.operationID, radix: 16))"))
        checks.append(CheckResult("decode round-trip: payload == [0x01]",
                                  packet.payload == [0x01],
                                  "got \(hex(packet.payload))"))
    } else {
        checks.append(CheckResult("decode round-trip: valid frame decodes", false, "got nil"))
    }

    // CRC mismatch → reject.
    var badCRC = frame
    badCRC[badCRC.count - 1] ^= 0xFF
    checks.append(CheckResult("decode rejects CRC mismatch", PacketDecoder.decode(badCRC) == nil))

    // Too short → reject.
    checks.append(CheckResult("decode rejects truncated frame",
                              PacketDecoder.decode([0x55, 0x60, 0x01]) == nil))

    // Wrong magic byte → reject.
    var badMagic = frame
    badMagic[0] = 0x00
    checks.append(CheckResult("decode rejects wrong magic", PacketDecoder.decode(badMagic) == nil))

    return checks
}

// MARK: - Typed payload decoders (battery / latency / in-ear)
// Frames are synthetic: these decoders read absolute offsets and do not validate
// CRC (matching the app, which parses already-received bytes).

private func payloadDecoderChecks() -> [CheckResult] {
    var checks: [CheckResult] = []

    // Battery: count=2 at [8]; left(0x02)=85 not charging (0x55); right(0x03)=72 charging (0xC8).
    let batteryFrame: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, /*[8]*/ 2, /*[9]*/ 0x02, /*[10]*/ 0x55, /*[11]*/ 0x03, /*[12]*/ 0xC8]
    let battery = PayloadDecoder.battery(batteryFrame)
    let expectedBattery = BatteryStatus(left: 85, right: 72, caseLevel: nil,
                                        leftCharging: false, rightCharging: true, caseCharging: false)
    checks.append(CheckResult("battery: L=85 noCharge, R=72 charging, case=nil",
                              battery == expectedBattery,
                              "got \(battery)"))

    // Battery on a too-short frame → empty status, no crash.
    checks.append(CheckResult("battery: short frame → empty status",
                              PayloadDecoder.battery([0x55, 0x60]) == BatteryStatus(),
                              "got \(PayloadDecoder.battery([0x55, 0x60]))"))

    // Latency: frame[8] == 0x01 → true; 0x00 → false.
    checks.append(CheckResult("latency: [8]=0x01 → true",
                              PayloadDecoder.latencyEnabled([0, 0, 0, 0, 0, 0, 0, 0, 0x01]) == true))
    checks.append(CheckResult("latency: [8]=0x00 → false",
                              PayloadDecoder.latencyEnabled([0, 0, 0, 0, 0, 0, 0, 0, 0x00]) == false))

    // In-ear: frame[10] != 0 → true; == 0 → false; short → false.
    checks.append(CheckResult("inEar: [10]=0x01 → true",
                              PayloadDecoder.inEarEnabled([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01]) == true))
    checks.append(CheckResult("inEar: [10]=0x00 → false",
                              PayloadDecoder.inEarEnabled([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x00]) == false))
    checks.append(CheckResult("inEar: short frame → false",
                              PayloadDecoder.inEarEnabled([0x55, 0x60, 0x01]) == false))

    return checks
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
