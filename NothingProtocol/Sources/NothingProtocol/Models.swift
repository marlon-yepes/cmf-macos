/// Decoded battery state. A `nil` level means that device was not reported in
/// the frame (i.e. not connected).
public struct BatteryStatus: Equatable {
    public var left: Int?
    public var right: Int?
    public var caseLevel: Int?
    public var leftCharging: Bool
    public var rightCharging: Bool
    public var caseCharging: Bool

    public init(left: Int? = nil,
                right: Int? = nil,
                caseLevel: Int? = nil,
                leftCharging: Bool = false,
                rightCharging: Bool = false,
                caseCharging: Bool = false) {
        self.left = left
        self.right = right
        self.caseLevel = caseLevel
        self.leftCharging = leftCharging
        self.rightCharging = rightCharging
        self.caseCharging = caseCharging
    }
}

/// Ear-tip fit-test result per side (raw seal-quality bytes, as reported).
public struct EarTipResult: Equatable {
    public let left: UInt8
    public let right: UInt8
    public init(left: UInt8, right: UInt8) {
        self.left = left
        self.right = right
    }
}

/// Enhanced-bass state: whether it is enabled and its level (0–7).
public struct EnhancedBass: Equatable {
    public let enabled: Bool
    public let level: Int
    public init(enabled: Bool, level: Int) {
        self.enabled = enabled
        self.level = level
    }
}

/// One gesture binding: a gesture on a given earbud mapped to an action code.
public struct GestureAssignment: Equatable {
    public let device: DeviceType
    public let gesture: GestureType
    public let action: UInt8
    public init(device: DeviceType, gesture: GestureType, action: UInt8) {
        self.device = device
        self.gesture = gesture
        self.action = action
    }
}

/// Custom EQ gains (dB) for the three bands.
public struct CustomEQ: Equatable {
    public let bass: Float
    public let mid: Float
    public let treble: Float
    public init(bass: Float, mid: Float, treble: Float) {
        self.bass = bass
        self.mid = mid
        self.treble = treble
    }
}
