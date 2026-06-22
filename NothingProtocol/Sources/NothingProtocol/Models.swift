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
