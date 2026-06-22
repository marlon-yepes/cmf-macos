/// ANC mode, mirroring the app's `ANC` enum raw values.
public enum ANCMode: UInt8 {
    case onHigh = 0x01
    case onMid = 0x02
    case onLow = 0x03
    case adaptive = 0x04
    case off = 0x05
    case transparency = 0x07
}

/// Equalizer preset, mirroring the app's `EQProfiles` enum raw values.
public enum EQProfile: UInt8 {
    case balanced = 0
    case voice = 1
    case moreTreble = 2
    case moreBass = 3
    case custom = 6
}
