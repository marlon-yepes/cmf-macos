import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Keep the app alive (in the menu bar) when the main window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
