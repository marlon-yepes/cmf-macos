import Foundation

/// CRC-16/MODBUS — initial value `0xFFFF`, reflected polynomial `0xA001`.
///
/// Ported verbatim from the app's `CRC16.crc16(buffer:)` so that packets produced
/// and validated here stay byte-compatible with the existing implementation.
public func crc16(_ bytes: [UInt8]) -> UInt16 {
    let initialValue: UInt16 = 0xFFFF
    let polynomial: UInt16 = 0xA001
    var crc = initialValue
    for byte in bytes {
        crc ^= UInt16(byte)
        for _ in 0..<8 {
            crc = (crc & 0x0001) != 0 ? (crc >> 1) ^ polynomial : crc >> 1
        }
    }
    return crc
}
