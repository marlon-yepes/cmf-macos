/// A validated inbound frame: header fields plus the extracted payload.
public struct InboundPacket: Equatable {
    /// 16-bit command code (`bytes[3] << 8 | bytes[4]`).
    public let command: UInt16
    /// Operation ID echoed by the device (`bytes[7]`).
    public let operationID: UInt8
    /// Payload bytes between the header and the trailing CRC.
    public let payload: [UInt8]
    /// The full raw frame, as received.
    public let raw: [UInt8]

    public init(command: UInt16, operationID: UInt8, payload: [UInt8], raw: [UInt8]) {
        self.command = command
        self.operationID = operationID
        self.payload = payload
        self.raw = raw
    }
}
