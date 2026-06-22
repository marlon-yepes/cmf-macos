import SwiftUI

/// Dedicated, resizable main window: a sidebar of sections with a detail pane.
/// Each section gets its own navigation stack so `NavigationLink` pushes inside
/// reused views happen within the window (independent of the menu-bar popover).
struct MainWindowView: View {
    @EnvironmentObject private var viewModel: MainViewViewModel
    @State private var section: MainSection? = .home
    @State private var path = NavigationPath()

    var body: some View {
        NavigationSplitView {
            List(MainSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.systemImage).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            NavigationStack(path: $path) {
                root(for: section ?? .home)
                    .navigationDestination(for: Destination.self) { DestinationView(destination: $0) }
            }
        }
        .frame(minWidth: 640, minHeight: 420)
        .onChange(of: section) { _ in path = NavigationPath() } // reset depth on section switch
    }

    @ViewBuilder
    private func root(for section: MainSection) -> some View {
        switch section {
        case .home: HomeView()
        case .equalizer: EqualizerView(eqMode: $viewModel.eqProfiles)
        case .controls: ControlsView()
        case .findMyBuds: FindMyBudsView()
        case .settings: SettingsView()
        }
    }
}
