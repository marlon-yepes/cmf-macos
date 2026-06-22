/// Parses and validates inbound RFCOMM frames.
///
/// Unlike the app's current inline parsing (which reads fixed offsets directly),
/// this rejects malformed input defensively: any frame that is too short, lacks
/// the magic byte, or fails CRC validation yields `nil` instead of crashing or
/// reading out of bounds.
public enum PacketDecoder {

    /// Minimum frame size: 8-byte header + 2-byte CRC.
    static let minimumLength = ProtocolConstants.headerLength + ProtocolConstants.crcLength

    public static func decode(_ bytes: [UInt8]) -> InboundPacket? {
        guard bytes.count >= minimumLength else { return nil }
        guard bytes[0] == ProtocolConstants.magic else { return nil }

        // Trailing CRC is little-endian (low byte first), over everything before it.
        let crcStart = bytes.count - ProtocolConstants.crcLength
        let body = Array(bytes[0..<crcStart])
        let received = UInt16(bytes[crcStart]) | (UInt16(bytes[crcStart + 1]) << 8)
        guard crc16(body) == received else { return nil }

        let command = (UInt16(bytes[ProtocolConstants.commandHighIndex]) << 8)
            | UInt16(bytes[ProtocolConstants.commandLowIndex])
        let operationID = bytes[ProtocolConstants.operationIDIndex]
        let payload = Array(bytes[ProtocolConstants.payloadStartIndex..<crcStart])

        return InboundPacket(command: command,
                             operationID: operationID,
                             payload: payload,
                             raw: bytes)
    }
}
