# Dedicated Window App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or
> superpowers:subagent-driven-development to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated, openable main window (sidebar + detail) alongside the existing menu-bar popover, reusing the current SwiftUI section views.

**Architecture:** Add a second `WindowGroup` scene to `Nothing_X_MacOSApp` showing a `NavigationSplitView` (sidebar of sections → detail). The detail uses the window's own `NavigationStack`, and the per-`Destination` view mapping is extracted from the App into a shared `DestinationView` so both the menu bar and the window reuse it. Flip `LSUIElement` to `NO` for a Dock icon; keep the app alive when the window closes (menu bar persists).

**Tech Stack:** SwiftUI (macOS 13+), `NavigationSplitView`, `WindowGroup`, `NSApplicationDelegateAdaptor`. No new dependencies.

## Global Constraints

- UI-only: no changes to device/protocol logic; reuse existing views and the shared `@StateObject`s (`Store`, `MainViewViewModel`, `BudsPickerComponentViewModel`).
- Keep the existing `MenuBarExtra` scene working.
- No XCTest for this UI work — each task is verified by **building and running** with Xcode (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild … build`, then launch and observe).
- Module name is `Nothing_X_MacOS`. Build via scheme `"Nothing X MacOS"`.
- v1 reuses views as-is (relax obvious fixed widths only); deep per-section redesign is a follow-up.

**Build/run commands used in every task:**
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project "Nothing X MacOS.xcodeproj" -scheme "Nothing X MacOS" \
  -destination 'platform=macOS' -configuration Debug build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES -quiet
# run: open the built .app from the build Products dir
```

---

### Task 1: Regular-app shell + empty window that builds and opens

**Files:**
- Modify: `Nothing X MacOS.xcodeproj/project.pbxproj` (set `INFOPLIST_KEY_LSUIElement = NO`, both Debug & Release)
- Create: `Nothing X MacOS/presentation/MainSection.swift`
- Create: `Nothing X MacOS/presentation/views/MainWindowView.swift`
- Create: `Nothing X MacOS/presentation/AppDelegate.swift`
- Modify: `Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift`

**Interfaces:**
- Produces: `enum MainSection: String, CaseIterable, Identifiable { case home, equalizer, controls, findMyBuds, settings }` with `var title: String` and `var systemImage: String`.
- Produces: `struct MainWindowView: View` (reads the three env objects).
- Produces: `final class AppDelegate: NSObject, NSApplicationDelegate` with `applicationShouldTerminateAfterLastWindowClosed(_:) -> Bool` returning `false`.

- [ ] **Step 1: Set the app to a regular (Dock) app.** In `project.pbxproj`, change both
  occurrences of `INFOPLIST_KEY_LSUIElement = YES;` to `INFOPLIST_KEY_LSUIElement = NO;`.

- [ ] **Step 2: Create `MainSection.swift`:**
```swift
import SwiftUI

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
```

- [ ] **Step 3: Create `AppDelegate.swift`:**
```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep the app alive (in the menu bar) when the main window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

- [ ] **Step 4: Create a placeholder `MainWindowView.swift`:**
```swift
import SwiftUI

struct MainWindowView: View {
    @State private var section: MainSection? = .home

    var body: some View {
        NavigationSplitView {
            List(MainSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.systemImage).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text((section ?? .home).title)   // placeholder; real views in Task 2
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 420)
    }
}
```

- [ ] **Step 5: Add the window scene + delegate to the App.** In `Nothing_X_MacOSApp.swift`,
  add `@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate` to the struct,
  and change `var body: some Scene { … }` to include BOTH scenes (keep the existing
  `MenuBarExtra { … } label: { … }.menuBarExtraStyle(.window)` exactly as-is, then add):
```swift
        WindowGroup("Nothing X", id: "main") {
            MainWindowView()
                .environmentObject(store)
                .environmentObject(viewModel)
                .environmentObject(budsPickerViewModel)
        }
        .windowResizability(.contentMinSize)
```

- [ ] **Step 6: Build & run.**
  Run the build command (Global Constraints). Expected: **BUILD SUCCEEDED** (exit 0).
  Launch the `.app`. Expected: a Dock icon appears; a resizable window opens with a
  sidebar (Device/Equalizer/Controls/Find My Buds/Settings); selecting an item shows its
  title in the detail; the menu-bar icon still works.

- [ ] **Step 7: Commit.**
```bash
git add "Nothing X MacOS.xcodeproj/project.pbxproj" "Nothing X MacOS/presentation/MainSection.swift" \
        "Nothing X MacOS/presentation/AppDelegate.swift" "Nothing X MacOS/presentation/views/MainWindowView.swift" \
        "Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift"
git commit -m "feat(ui): regular-app window shell (sidebar) alongside menu bar"
```

---

### Task 2: Shared `DestinationView` + real section views in the detail

**Files:**
- Create: `Nothing X MacOS/presentation/views/DestinationView.swift`
- Modify: `Nothing X MacOS/presentation/views/MainWindowView.swift`
- Modify: `Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift` (menu bar reuses `DestinationView`)

**Interfaces:**
- Produces: `struct DestinationView: View { let destination: Destination }` — reads
  `@EnvironmentObject var viewModel: MainViewViewModel` and renders the same mapping the
  App's `navigationDestination` switch currently does.
- Consumes (Task 1): `MainSection`, `MainWindowView`.

- [ ] **Step 1: Create `DestinationView.swift`** by lifting the App's existing `switch`
  (the `navigationDestination(for: Destination.self)` body and the `controlsDetailView`
  helper) verbatim into a view that owns the bindings via the environment view model:
```swift
import SwiftUI

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
```

- [ ] **Step 2: Refactor the menu bar to reuse it.** In `Nothing_X_MacOSApp.swift`, replace
  the inline `switch(destination) { … }` inside `.navigationDestination(for: Destination.self)`
  with `DestinationView(destination: destination)`, and delete the now-unused private
  `controlsDetailView` helper from the App struct.

- [ ] **Step 3: Wire real views into the window detail.** Replace `MainWindowView`'s detail
  with a window-local navigation stack that renders the selected section's root and supports
  the section views' `NavigationLink(value:)` pushes locally:
```swift
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
        .onChange(of: section) { _ in path = NavigationPath() }  // reset depth when switching section
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
```

- [ ] **Step 4: Build & run.** Expected: BUILD SUCCEEDED. Launch; each sidebar section
  renders its real view in the detail. Inside Settings, tapping "EAR TIP FIT TEST" / "CASE
  LED COLOR" / "FIND MY EARBUDS" pushes that screen **within the window**; the menu-bar
  popover navigation is unaffected (independent stacks).

- [ ] **Step 5: Commit.**
```bash
git add "Nothing X MacOS/presentation/views/DestinationView.swift" \
        "Nothing X MacOS/presentation/views/MainWindowView.swift" \
        "Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift"
git commit -m "feat(ui): window detail reuses section views via shared DestinationView"
```

---

### Task 3: Sidebar footer (status + battery) and frame relaxation

**Files:**
- Modify: `Nothing X MacOS/presentation/views/MainWindowView.swift`
- Modify: section views only IF they hard-code a narrow width that looks cramped (e.g. a
  `.frame(width: 250)`); relax to `maxWidth: .infinity` or wrap in a flexible container.

**Interfaces:** consumes `MainViewViewModel` published properties already used by the menu
bar label (`leftBattery`, `rightBattery`) and the device name shown in `HomeView`.

- [ ] **Step 1: Add a sidebar footer** showing connection/device + battery. In
  `MainWindowView`, attach a `.safeAreaInset(edge: .bottom)` to the sidebar `List`:
```swift
.safeAreaInset(edge: .bottom) {
    VStack(alignment: .leading, spacing: 2) {
        Divider()
        if let l = viewModel.leftBattery, let r = viewModel.rightBattery {
            Text("L \(Int(l))%   R \(Int(r))%").font(.caption).foregroundStyle(.secondary)
        } else {
            Text("Not connected").font(.caption).foregroundStyle(.secondary)
        }
    }
    .padding(8)
    .frame(maxWidth: .infinity, alignment: .leading)
}
```
  (If `leftBattery`/`rightBattery` are non-optional or named differently, adapt to the actual
  published properties used by the menu-bar `batteryText` computed property in the App.)

- [ ] **Step 2: Build & run.** Expected: BUILD SUCCEEDED. Sidebar shows battery when a device
  is connected, "Not connected" otherwise.

- [ ] **Step 3: Relax cramped frames (only if observed).** While running, note any section that
  looks pinned to ~250px in the wide detail. For each, open its view file and replace a fixed
  `.frame(width: N)` with `.frame(maxWidth: .infinity)` (or remove it). Rebuild and re-observe.
  If a view needs real redesign to look good wide, DO NOT do it here — note it in the spec's
  follow-ups and move on.

- [ ] **Step 4: Commit.**
```bash
git add -A
git commit -m "feat(ui): sidebar battery/status footer; relax fixed widths for window"
```

---

### Task 4: Open-window affordances (menu-bar item + Dock reopen)

**Files:**
- Modify: `Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift` (menu-bar "Open Window" button)
- Modify: `Nothing X MacOS/presentation/AppDelegate.swift` (reopen on Dock click)

**Interfaces:** consumes the `WindowGroup` id `"main"` (Task 1) via `@Environment(\.openWindow)`.

- [ ] **Step 1: Add an "Open Window" affordance** to the menu-bar content. Inside the
  `MenuBarExtra { … }` content (e.g. just below the `NavigationStack`), add:
```swift
Divider()
Button("Open Main Window") { openWindow(id: "main") }
    .keyboardShortcut("o")
```
  and add `@Environment(\.openWindow) private var openWindow` to the App struct.

- [ ] **Step 2: Reopen window on Dock-icon click** when none is open. In `AppDelegate`:
```swift
func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag { NSApp.activate(ignoringOtherApps: true) }
    return true   // let AppKit restore/recreate the window
}
```

- [ ] **Step 3: Build & run.** Expected: BUILD SUCCEEDED. Verify: (a) close the window with
  ⌘W/red button → app stays alive (menu-bar icon remains); (b) click the Dock icon → window
  reopens; (c) the menu-bar "Open Main Window" item opens/focuses it; (d) ⌘Q quits.

- [ ] **Step 4: Commit.**
```bash
git add "Nothing X MacOS/presentation/Nothing_X_MacOSApp.swift" "Nothing X MacOS/presentation/AppDelegate.swift"
git commit -m "feat(ui): open main window from menu bar and Dock reopen"
```

---

## Self-Review

- **Spec coverage:** §3 window scene → Task 1; §4 sidebar+detail + DestinationView → Tasks 1–2;
  §4 shared env state → Task 1 Step 5; §5 close≠quit/reopen → Tasks 1 & 4; sidebar footer →
  Task 3; LSUIElement=NO → Task 1 Step 1; §7 verification → build+run steps in every task.
  Reuse strategy (§6) → Task 3 Step 3. Covered.
- **Placeholders:** none — every code step is concrete. The one conditional ("adapt to actual
  published property") references the App's existing `batteryText` for the exact names, which
  is a real, locatable source, not a TBD.
- **Type consistency:** `MainSection`, `MainWindowView`, `DestinationView`, `AppDelegate`,
  window id `"main"`, `Destination` (existing) used consistently across tasks.
- **Note:** v1 discovery/pairing is still initiated from the menu bar (window assumes the
  shared connection state); a Discover entry point in the window is a follow-up.
