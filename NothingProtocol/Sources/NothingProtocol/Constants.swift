/// Named constants for the RFCOMM packet layout, replacing the magic numbers
/// scattered through the app's `send`/`read*` functions.
///
/// Outbound packet layout (mirrors `NothingServiceImpl.send`):
/// ```
/// [0]=0x55 [1]=0x60 [2]=0x01 [3]=cmdHi [4]=cmdLo [5]=payloadLen [6]=0x00 [7]=opID  payload...  crcLo crcHi
/// ```
public enum ProtocolConstants {
    /// First byte of every frame.
    public static let magic: UInt8 = 0x55
    /// The fixed 8-byte header template used when encoding a command.
    public static let headerTemplate: [UInt8] = [0x55, 0x60, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
    public static let headerLength = 8
    public static let crcLength = 2

    // Header field offsets.
    public static let commandHighIndex = 3
    public static let commandLowIndex = 4
    public static let payloadLengthIndex = 5
    public static let operationIDIndex = 7
    public static let payloadStartIndex = 8

    // Battery payload decoding.
    public static let batteryLevelMask: UInt8 = 0x7F   // 127
    public static let chargingMask: UInt8 = 0x80       // 128
    public static let deviceIDLeft: UInt8 = 0x02
    public static let deviceIDRight: UInt8 = 0x03
    public static let deviceIDCase: UInt8 = 0x04
}
