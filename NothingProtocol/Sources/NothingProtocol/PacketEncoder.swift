/// Builds outbound command frames. Byte-for-byte equivalent to
/// `NothingServiceImpl.send(command:operationID:payload:)`.
public enum PacketEncoder {

    /// Encode a command into a complete RFCOMM frame (header + payload + CRC).
    ///
    /// - Parameters:
    ///   - command: the command to send.
    ///   - operationID: defaults to `command.operationID` (the high byte of the
    ///     command), matching the app's behavior.
    ///   - payload: optional payload bytes; its length is written into the header
    ///     (clamped to a single byte, as the app does).
    public static func encode(command: Command,
                              operationID: UInt8? = nil,
                              payload: [UInt8] = []) -> [UInt8] {
        var frame = ProtocolConstants.headerTemplate

        let raw = command.rawValue
        frame[ProtocolConstants.commandHighIndex] = UInt8(raw >> 8)
        frame[ProtocolConstants.commandLowIndex] = UInt8(raw & 0xFF)
        frame[ProtocolConstants.payloadLengthIndex] = UInt8(clamping: payload.count)
        frame[ProtocolConstants.operationIDIndex] = operationID ?? command.operationID

        frame.append(contentsOf: payload)

        let crc = crc16(frame)
        frame.append(UInt8(crc & 0xFF))         // low byte first
        frame.append(UInt8((crc >> 8) & 0xFF))  // then high byte
        return frame
    }
}
