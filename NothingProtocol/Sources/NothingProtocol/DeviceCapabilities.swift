/// Per-model feature matrix. The UI reads this (keyed by `Codenames`) to decide
/// which controls to expose. Ported verbatim from the app's
/// `domain/enums/device/DeviceCapabilities.swift`.
public struct DeviceCapabilities: Equatable {
    public let supportsCustomEQ: Bool
    public let supportsEnhancedBass: Bool
    public let supportsPersonalizedANC: Bool
    public let supportsEarTipTest: Bool
    public let supportsCaseLED: Bool
    public let supportsANCCycleConfig: Bool
    public let supportsDoubleTap: Bool
    public let supportsDoubleTapAndHold: Bool

    public init(supportsCustomEQ: Bool,
                supportsEnhancedBass: Bool,
                supportsPersonalizedANC: Bool,
                supportsEarTipTest: Bool,
                supportsCaseLED: Bool,
                supportsANCCycleConfig: Bool,
                supportsDoubleTap: Bool,
                supportsDoubleTapAndHold: Bool) {
        self.supportsCustomEQ = supportsCustomEQ
        self.supportsEnhancedBass = supportsEnhancedBass
        self.supportsPersonalizedANC = supportsPersonalizedANC
        self.supportsEarTipTest = supportsEarTipTest
        self.supportsCaseLED = supportsCaseLED
        self.supportsANCCycleConfig = supportsANCCycleConfig
        self.supportsDoubleTap = supportsDoubleTap
        self.supportsDoubleTapAndHold = supportsDoubleTapAndHold
    }

    /// No capabilities — used for `UNKNOWN` / unrecognized devices.
    public static let none = DeviceCapabilities(
        supportsCustomEQ: false, supportsEnhancedBass: false, supportsPersonalizedANC: false,
        supportsEarTipTest: false, supportsCaseLED: false, supportsANCCycleConfig: false,
        supportsDoubleTap: false, supportsDoubleTapAndHold: false)

    public static func capabilities(for codename: Codenames) -> DeviceCapabilities {
        switch codename {
        case .ONE: // Ear (1)
            return DeviceCapabilities(supportsCustomEQ: false, supportsEnhancedBass: false,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: true,
                supportsANCCycleConfig: false, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .TWO: // Ear (2)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: false,
                supportsPersonalizedANC: true, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .TWOS: // Ear (2024)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .ESPEON:
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .DONPHAN:
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .CLEFFA:
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: false)
        case .CORSOLA: // Ear (a)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: false,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .STICKS: // Ear (stick)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: false,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: false, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .FLAFFY: // Ear (open)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: false,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: false, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .CROBAT:
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: false,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: false, supportsDoubleTap: false, supportsDoubleTapAndHold: false)
        case .EAR3: // Ear (3)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .GIRAFARIG: // CMF Buds 2
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .GLIGAR: // CMF Buds 2 Plus
            return DeviceCapabilities(supportsCustomEQ: false, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: true, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .HOOTHOOT: // CMF Buds 2a
            return DeviceCapabilities(supportsCustomEQ: false, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .ELEKID: // Nothing Headphone (1)
            return DeviceCapabilities(supportsCustomEQ: true, supportsEnhancedBass: true,
                supportsPersonalizedANC: false, supportsEarTipTest: false, supportsCaseLED: false,
                supportsANCCycleConfig: true, supportsDoubleTap: true, supportsDoubleTapAndHold: true)
        case .UNKNOWN:
            return .none
        }
    }
}
