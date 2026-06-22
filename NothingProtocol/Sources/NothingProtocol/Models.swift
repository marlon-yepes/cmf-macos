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
