import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Keep the app alive (in the menu bar) when the main window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Re-activate the app when its Dock icon is clicked with no visible window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSApp.activate(ignoringOtherApps: true) }
        return true
    }
}
