import SwiftUI

/// Top-level sections shown in the dedicated window's sidebar.
enum MainSection: String, CaseIterable, Identifiable {
    case home, equalizer, controls, findMyBuds, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Device"
        case .equalizer: return "Equalizer"
        case .controls: return "Controls"
        case .findMyBuds: return "Find My Buds"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "airpodspro"
        case .equalizer: return "slider.horizontal.3"
        case .controls: return "hand.tap"
        case .findMyBuds: return "wave.3.right"
        case .settings: return "gearshape"
        }
    }
}
