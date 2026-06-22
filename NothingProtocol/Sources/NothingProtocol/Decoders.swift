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
}
