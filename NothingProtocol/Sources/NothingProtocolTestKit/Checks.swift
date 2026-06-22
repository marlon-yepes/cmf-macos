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
    results.append(contentsOf: extendedDecoderChecks())
    results.append(contentsOf: deviceChecks())
    results.append(contentsOf: gestureAndCustomEQChecks())
    return results
}

// MARK: - Gestures & custom EQ (float decoding)

private func gestureAndCustomEQChecks() -> [CheckResult] {
    var checks: [CheckResult] = []

    // eqFloat: little-endian IEEE-754. 1.0 = 0x3F800000 → LE bytes 00 00 80 3F.
    checks.append(CheckResult("eqFloat([00,00,80,3F]) == 1.0",
                              PayloadDecoder.eqFloat([0x00, 0x00, 0x80, 0x3F]) == 1.0,
                              "got \(PayloadDecoder.eqFloat([0x00, 0x00, 0x80, 0x3F]))"))
    // -6.0 = 0xC0C00000 → LE bytes 00 00 C0 C0.
    checks.append(CheckResult("eqFloat([00,00,C0,C0]) == -6.0",
                              PayloadDecoder.eqFloat([0x00, 0x00, 0xC0, 0xC0]) == -6.0,
                              "got \(PayloadDecoder.eqFloat([0x00, 0x00, 0xC0, 0xC0]))"))

    // customEQ: treble@14, bass@27, mid@40 (4 bytes each), min 44 bytes.
    var eq = [UInt8](repeating: 0, count: 44)
    eq[14] = 0x00; eq[15] = 0x00; eq[16] = 0x80; eq[17] = 0x3F  // treble = 1.0
    eq[27] = 0x00; eq[28] = 0x00; eq[29] = 0xC0; eq[30] = 0xC0  // bass = -6.0
    eq[40] = 0x00; eq[41] = 0x00; eq[42] = 0x00; eq[43] = 0x00  // mid = 0.0
    let customEQExpected = CustomEQ(bass: -6.0, mid: 0.0, treble: 1.0)
    checks.append(CheckResult("customEQ: bass=-6 mid=0 treble=1",
                              PayloadDecoder.customEQ(eq) == customEQExpected,
                              "got \(String(describing: PayloadDecoder.customEQ(eq)))"))
    checks.append(CheckResult("customEQ: short frame (<44) → nil",
                              PayloadDecoder.customEQ([0x55, 0x60]) == nil))

    // gestures: count=1 at [8]; device@9, gesture@11, action@12.
    var g = [UInt8](repeating: 0, count: 13)
    g[8] = 1; g[9] = 2 /* LEFT */; g[11] = 2 /* DOUBLE_TAP */; g[12] = 5 /* action */
    let gExpected = [GestureAssignment(device: .LEFT, gesture: .DOUBLE_TAP, action: 5)]
    checks.append(CheckResult("gestures: 1 entry LEFT/DOUBLE_TAP/action=5",
                              PayloadDecoder.gestures(g) == gExpected,
                              "got \(PayloadDecoder.gestures(g))"))
    // Unknown gesture code is skipped, not crashed.
    var gBad = [UInt8](repeating: 0, count: 13)
    gBad[8] = 1; gBad[9] = 2; gBad[11] = 99 /* unknown */; gBad[12] = 5
    checks.append(CheckResult("gestures: unknown gesture → skipped (empty)",
                              PayloadDecoder.gestures(gBad).isEmpty))

    return checks
}

// MARK: - Device identification & capabilities

private func deviceChecks() -> [CheckResult] {
    var checks: [CheckResult] = []

    // Serial → SKU → codename (CMF Buds 2 black: serial code "84").
    let sku = skuFromSerial(serial: "SH0084000000")
    checks.append(CheckResult("skuFromSerial(SH..84..) == GIRAFARIG_BLACK",
                              sku == .GIRAFARIG_BLACK, "got \(sku.rawValue)"))
    checks.append(CheckResult("codenameFromSKU(GIRAFARIG_BLACK) == GIRAFARIG",
                              codenameFromSKU(sku: .GIRAFARIG_BLACK) == .GIRAFARIG))
    checks.append(CheckResult("skuFromSerial(placeholder) == EAR_1_WHITE",
                              skuFromSerial(serial: "12345678901234567") == .EAR_1_WHITE))
    checks.append(CheckResult("skuFromSerial(empty) == UNKNOWN",
                              skuFromSerial(serial: "") == .UNKNOWN))

    // Bluetooth name → codename.
    checks.append(CheckResult("name 'Nothing Ear (2)' → TWO",
                              codenameFromDeviceName(name: "Nothing Ear (2)") == .TWO))
    checks.append(CheckResult("name 'CMF Buds 2 Plus' → GLIGAR",
                              codenameFromDeviceName(name: "CMF Buds 2 Plus") == .GLIGAR))
    checks.append(CheckResult("name 'CMF Buds 2' → GIRAFARIG",
                              codenameFromDeviceName(name: "CMF Buds 2") == .GIRAFARIG))
    checks.append(CheckResult("name 'Nothing Ear (3)' → EAR3",
                              codenameFromDeviceName(name: "Nothing Ear (3)") == .EAR3))

    // CMF Buds Pro 2: now recognized by name (provisional → ESPEON / B172).
    checks.append(CheckResult("name 'CMF Buds Pro 2' → ESPEON (provisional)",
                              codenameFromDeviceName(name: "CMF Buds Pro 2") == .ESPEON,
                              "got \(codenameFromDeviceName(name: "CMF Buds Pro 2").rawValue)"))
    checks.append(CheckResult("name 'cmf buds pro 2' (case-insensitive) → ESPEON",
                              codenameFromDeviceName(name: "cmf buds pro 2") == .ESPEON))
    // Regression guard: 'CMF Buds 2' must NOT be captured by the Pro 2 branch.
    checks.append(CheckResult("name 'CMF Buds 2' still → GIRAFARIG (not Pro 2)",
                              codenameFromDeviceName(name: "CMF Buds 2") == .GIRAFARIG))

    // Capabilities table.
    let ear3 = DeviceCapabilities.capabilities(for: .EAR3)
    checks.append(CheckResult("caps(EAR3): customEQ && earTipTest",
                              ear3.supportsCustomEQ && ear3.supportsEarTipTest))
    checks.append(CheckResult("caps(GIRAFARIG): enhancedBass",
                              DeviceCapabilities.capabilities(for: .GIRAFARIG).supportsEnhancedBass))
    checks.append(CheckResult("caps(UNKNOWN) == none (all false)",
                              DeviceCapabilities.capabilities(for: .UNKNOWN) == .none))

    return checks
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

// MARK: - Typed payload decoders (ANC / EQ / firmware / serial / ear-tip / etc.)

private func extendedDecoderChecks() -> [CheckResult] {
    var checks: [CheckResult] = []

    // ANC: status byte at [9].
    checks.append(CheckResult("anc: [9]=0x07 → transparency",
                              PayloadDecoder.ancMode([0, 0, 0, 0, 0, 0, 0, 0, 0, 0x07]) == .transparency))
    checks.append(CheckResult("anc: [9]=0x05 → off",
                              PayloadDecoder.ancMode([0, 0, 0, 0, 0, 0, 0, 0, 0, 0x05]) == .off))
    checks.append(CheckResult("anc: [9]=0x09 unknown → nil",
                              PayloadDecoder.ancMode([0, 0, 0, 0, 0, 0, 0, 0, 0, 0x09]) == nil))

    // EQ: mode at [8].
    checks.append(CheckResult("eq: [8]=3 → moreBass",
                              PayloadDecoder.eqProfile([0, 0, 0, 0, 0, 0, 0, 0, 3]) == .moreBass))
    checks.append(CheckResult("eq: [8]=99 unknown → balanced",
                              PayloadDecoder.eqProfile([0, 0, 0, 0, 0, 0, 0, 0, 99]) == .balanced))

    // Firmware: [5]=size=3, characters "1.2" at [8..10].
    let fw: [UInt8] = [0, 0, 0, 0, 0, 3, 0, 0, 0x31, 0x2E, 0x32]
    checks.append(CheckResult("firmware: size=3 → \"1.2\"",
                              PayloadDecoder.firmware(fw) == "1.2",
                              "got \"\(PayloadDecoder.firmware(fw))\""))

    // Serial: UTF-8 lines from [7]; first type==4 value.
    let serialFrame: [UInt8] = [0, 0, 0, 0, 0, 0, 0] + Array("1,4,ABCDEFG".utf8)
    checks.append(CheckResult("serial: type 4 value → ABCDEFG",
                              PayloadDecoder.serial(serialFrame) == "ABCDEFG",
                              "got \"\(PayloadDecoder.serial(serialFrame))\""))
    checks.append(CheckResult("serial: short frame → default",
                              PayloadDecoder.serial([0x55, 0x60]) == PayloadDecoder.defaultSerial))

    // Ear-tip: [8]=left, [9]=right.
    checks.append(CheckResult("earTip: left=2 right=1",
                              PayloadDecoder.earTipResult([0, 0, 0, 0, 0, 0, 0, 0, 2, 1]) == EarTipResult(left: 2, right: 1)))

    // Advanced EQ: [8]==1.
    checks.append(CheckResult("advancedEQ: [8]=1 → true",
                              PayloadDecoder.advancedEQEnabled([0, 0, 0, 0, 0, 0, 0, 0, 1]) == true))

    // Enhanced bass: enabled [8], level [9]/2.
    checks.append(CheckResult("enhancedBass: enabled=true level=3",
                              PayloadDecoder.enhancedBass([0, 0, 0, 0, 0, 0, 0, 0, 1, 6]) == EnhancedBass(enabled: true, level: 3)))

    // Personalized ANC: [8]==1.
    checks.append(CheckResult("personalizedANC: [8]=1 → true",
                              PayloadDecoder.personalizedANCEnabled([0, 0, 0, 0, 0, 0, 0, 0, 1]) == true))

    // Case LED: count at [8]; RGB at 10 + i*4.
    let led: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0xAA, 0xBB, 0xCC]
    checks.append(CheckResult("caseLED: 1 LED → [[0xAA,0xBB,0xCC]]",
                              PayloadDecoder.caseLEDColors(led) == [[0xAA, 0xBB, 0xCC]],
                              "got \(PayloadDecoder.caseLEDColors(led).map(hex))"))

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
