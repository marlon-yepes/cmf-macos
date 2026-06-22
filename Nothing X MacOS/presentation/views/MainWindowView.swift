import SwiftUI

/// Dedicated, resizable main window: a sidebar of sections with a detail pane.
struct MainWindowView: View {
    @State private var section: MainSection? = .home

    var body: some View {
        NavigationSplitView {
            List(MainSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.systemImage).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text((section ?? .home).title) // placeholder; real views wired in Task 2
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 420)
    }
}
