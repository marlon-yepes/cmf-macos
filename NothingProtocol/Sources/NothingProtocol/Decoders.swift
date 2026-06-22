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
}
