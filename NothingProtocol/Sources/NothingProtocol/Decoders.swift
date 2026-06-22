/// Typed decoders for inbound payloads. Each function mirrors the corresponding
/// `read*` function in `NothingServiceImpl`, using the same absolute frame
/// offsets, but returns a value instead of mutating a device model — and never
/// reads out of bounds.
public enum PayloadDecoder {

    /// Mirrors `readBattery`. The byte at `payloadStartIndex` is the count of
    /// reported devices; each device is an (id, data) pair, where the low 7 bits
    /// are the level and the high bit is the charging flag.
    public static func battery(_ frame: [UInt8]) -> BatteryStatus {
        var status = BatteryStatus()
        let countIndex = ProtocolConstants.payloadStartIndex
        guard frame.count > countIndex else { return status }

        let deviceCount = Int(frame[countIndex])
        for i in 0..<deviceCount {
            let idIndex = countIndex + 1 + (i * 2)
            let dataIndex = countIndex + 2 + (i * 2)
            guard dataIndex < frame.count else { break }

            let deviceID = frame[idIndex]
            let data = frame[dataIndex]
            let level = Int(data & ProtocolConstants.batteryLevelMask)
            let charging = (data & ProtocolConstants.chargingMask) == ProtocolConstants.chargingMask

            switch deviceID {
            case ProtocolConstants.deviceIDLeft:
                status.left = level
                status.leftCharging = charging
            case ProtocolConstants.deviceIDRight:
                status.right = level
                status.rightCharging = charging
            case ProtocolConstants.deviceIDCase:
                status.caseLevel = level
                status.caseCharging = charging
            default:
                break
            }
        }
        return status
    }

    /// Mirrors `readLatencyMode`: low-latency is on iff `frame[8] == 0x01`.
    public static func latencyEnabled(_ frame: [UInt8]) -> Bool {
        let index = ProtocolConstants.payloadStartIndex
        guard frame.count > index else { return false }
        return frame[index] == 0x01
    }

    /// Mirrors `readInEarDetection`: detection is on iff `frame[10] != 0`.
    public static func inEarEnabled(_ frame: [UInt8]) -> Bool {
        let index = ProtocolConstants.payloadStartIndex + 2 // 10
        guard frame.count > index else { return false }
        return frame[index] != 0
    }

    /// Mirrors `readANC`: ANC status byte is at `frame[9]`. Returns `nil` for an
    /// unknown status (the app leaves the value unchanged in that case).
    public static func ancMode(_ frame: [UInt8]) -> ANCMode? {
        let index = ProtocolConstants.payloadStartIndex + 1 // 9
        guard frame.count > index else { return nil }
        return ANCMode(rawValue: frame[index])
    }

    /// Mirrors `readEQ`: EQ mode at `frame[8]`, defaulting to `.balanced`.
    public static func eqProfile(_ frame: [UInt8]) -> EQProfile {
        let index = ProtocolConstants.payloadStartIndex
        guard frame.count > index else { return .balanced }
        return EQProfile(rawValue: frame[index]) ?? .balanced
    }

    /// Mirrors `readFirmware`: `frame[5]` is the length; characters start at
    /// `frame[8]`. Reads only what is present (no out-of-bounds).
    public static func firmware(_ frame: [UInt8]) -> String {
        guard frame.count > ProtocolConstants.payloadStartIndex else { return "" }
        let size = Int(frame[ProtocolConstants.payloadLengthIndex])
        var version = ""
        for i in 0..<size {
            let index = ProtocolConstants.payloadStartIndex + i
            guard index < frame.count else { break }
            version += String(UnicodeScalar(frame[index]))
        }
        return version
    }

    /// Default serial returned by the app when none is found in the payload.
    public static let defaultSerial = "12345678901234567"

    /// Mirrors `readSerial`: UTF-8 lines from `frame[7]`, each
    /// `device,type,value`; the serial is the first `type == 4` value.
    public static func serial(_ frame: [UInt8]) -> String {
        guard frame.count >= ProtocolConstants.operationIDIndex else { return defaultSerial }
        let text = String(decoding: frame[ProtocolConstants.operationIDIndex...], as: UTF8.self)
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: ",").map(String.init)
            guard parts.count == 3,
                  Int(parts[0]) != nil,
                  let type = Int(parts[1]),
                  !parts[2].isEmpty else { continue }
            if type == 4 { return parts[2] }
        }
        return defaultSerial
    }

    /// Mirrors `readEarTipTestResult`: `frame[8]` = left, `frame[9]` = right.
    public static func earTipResult(_ frame: [UInt8]) -> EarTipResult? {
        let rightIndex = ProtocolConstants.payloadStartIndex + 1 // 9
        guard frame.count > rightIndex else { return nil }
        return EarTipResult(left: frame[ProtocolConstants.payloadStartIndex],
                            right: frame[rightIndex])
    }

    /// Mirrors `readAdvancedEQ`: enabled iff `frame[8] == 1`.
    public static func advancedEQEnabled(_ frame: [UInt8]) -> Bool {
        let index = ProtocolConstants.payloadStartIndex
        guard frame.count > index else { return false }
        return frame[index] == 1
    }

    /// Mirrors `readEnhancedBass`: enabled at `frame[8]`, level `frame[9] / 2`.
    public static func enhancedBass(_ frame: [UInt8]) -> EnhancedBass? {
        let levelIndex = ProtocolConstants.payloadStartIndex + 1 // 9
        guard frame.count > levelIndex else { return nil }
        return EnhancedBass(enabled: frame[ProtocolConstants.payloadStartIndex] == 1,
                            level: Int(frame[levelIndex]) / 2)
    }

    /// Mirrors `readPersonalizedANC`: enabled iff `frame[8] == 1`.
    public static func personalizedANCEnabled(_ frame: [UInt8]) -> Bool {
        let index = ProtocolConstants.payloadStartIndex
        guard frame.count > index else { return false }
        return frame[index] == 1
    }

    /// Mirrors `readCaseLED`: `frame[8]` = LED count; each LED is 3 RGB bytes at
    /// `10 + i*4`.
    public static func caseLEDColors(_ frame: [UInt8]) -> [[UInt8]] {
        let countIndex = ProtocolConstants.payloadStartIndex
        guard frame.count > countIndex else { return [] }
        let count = Int(frame[countIndex])
        var colors: [[UInt8]] = []
        for i in 0..<count {
            let base = countIndex + 2 + (i * 4) // 10 + i*4
            guard base + 2 < frame.count else { break }
            colors.append([frame[base], frame[base + 1], frame[base + 2]])
        }
        return colors
    }

    /// Decode a little-endian IEEE-754 float from 4 EQ bytes. Mirrors the app's
    /// `decodeFloatFromEQ`.
    public static func eqFloat(_ bytes: [UInt8]) -> Float {
        guard bytes.count >= 4 else { return 0.0 }
        let bitPattern = UInt32(bytes[3]) << 24 | UInt32(bytes[2]) << 16
            | UInt32(bytes[1]) << 8 | UInt32(bytes[0])
        return Float(bitPattern: bitPattern)
    }

    /// Mirrors `readCustomEQ`: 4-byte floats at offsets 14 (treble), 27 (bass),
    /// 40 (mid). Requires at least 44 bytes.
    public static func customEQ(_ frame: [UInt8]) -> CustomEQ? {
        guard frame.count >= 44 else { return nil }
        let treble = eqFloat(Array(frame[14..<18]))
        let bass = eqFloat(Array(frame[27..<31]))
        let mid = eqFloat(Array(frame[40..<44]))
        return CustomEQ(bass: bass, mid: mid, treble: treble)
    }

    /// Mirrors `readGestures`: `frame[8]` = count; each entry is 4 bytes —
    /// device at `9 + i*4`, gesture at `11 + i*4`, action at `12 + i*4`. Entries
    /// with an unknown device or gesture are skipped.
    public static func gestures(_ frame: [UInt8]) -> [GestureAssignment] {
        let countIndex = ProtocolConstants.payloadStartIndex
        guard frame.count > countIndex else { return [] }
        let count = Int(frame[countIndex])
        var result: [GestureAssignment] = []
        for i in 0..<count {
            let deviceIndex = countIndex + 1 + (i * 4)  // 9 + i*4
            let gestureIndex = countIndex + 3 + (i * 4) // 11 + i*4
            let actionIndex = countIndex + 4 + (i * 4)  // 12 + i*4
            guard actionIndex < frame.count else { break }
            guard let device = DeviceType(rawValue: frame[deviceIndex]),
                  let gesture = GestureType(rawValue: frame[gestureIndex]) else { continue }
            result.append(GestureAssignment(device: device, gesture: gesture, action: frame[actionIndex]))
        }
        return result
    }
}
