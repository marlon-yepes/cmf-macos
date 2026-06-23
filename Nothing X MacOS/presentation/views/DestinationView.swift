import SwiftUI

/// Maps a `Destination` to its view. Shared by the menu-bar popover and the
/// dedicated window so the navigation mapping lives in one place.
struct DestinationView: View {
    let destination: Destination
    @EnvironmentObject private var viewModel: MainViewViewModel

    var body: some View {
        switch destination {
        case .home: HomeView()
        case .equalizer: EqualizerView(eqMode: $viewModel.eqProfiles)
        case .controls: ControlsView()
        case .controlsTripleTap: controlsDetailView(.controlsTripleTap)
        case .controlsTapHold: controlsDetailView(.controlsTapHold)
        case .controlsDoubleTap: controlsDetailView(.controlsDoubleTap)
        case .controlsDoubleTapHold: controlsDetailView(.controlsDoubleTapHold)
        case .settings: SettingsView()
        case .findMyBuds: FindMyBudsView()
        case .discover: DiscoverView()
        case .connect: ConnectView()
        case .discover_started: DiscoverStartedView()
        case .bluetooth_off: BluetoothIsOffView()
        case .earTipTest: EarTipTestView()
        case .caseLED: CaseLEDView()
        }
    }

    @ViewBuilder
    private func controlsDetailView(_ destination: Destination) -> some View {
        ControlsDetailView(
            destination: destination,
            leftTripleTapAction: $viewModel.leftTripleTapAction,
            rightTripleTapAction: $viewModel.rightTripleTapAction,
            leftTapAndHoldAction: $viewModel.leftTapAndHoldAction,
            rightTapAndHoldAction: $viewModel.rightTapAndHoldAction,
            leftDoubleTapAction: $viewModel.leftDoubleTapAction,
            rightDoubleTapAction: $viewModel.rightDoubleTapAction,
            leftDoubleTapAndHoldAction: $viewModel.leftDoubleTapAndHoldAction,
            rightDoubleTapAndHoldAction: $viewModel.rightDoubleTapAndHoldAction
        )
    }
}
