/// Which earbud a gesture is bound to. Ported verbatim from the app's `DeviceType`.
public enum DeviceType: UInt8 {
    case LEFT = 2
    case RIGHT = 3
}

/// Gesture kind. Ported verbatim from the app's `GestureType`.
public enum GestureType: UInt8 {
    case DOUBLE_TAP = 2
    case TRIPLE_TAP = 3
    case TAP_AND_HOLD = 7
    case DOUBLE_TAP_AND_HOLD = 9
}
