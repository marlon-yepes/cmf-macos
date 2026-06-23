# Dedicated Window App — Design Spec

**Date:** 2026-06-22
**Status:** Approved (pending written-spec review)
**Author:** Marlon Yepes (with Claude)

## 1. Context

Today the app is a **menu-bar agent app**:
- `Nothing_X_MacOSApp` declares a single `MenuBarExtra` scene with
  `.menuBarExtraStyle(.window)`, a 250×230 popover containing a `NavigationStack`
  (Home → Equalizer → Controls → Gestures → Find My Buds → Settings → …).
- `INFOPLIST_KEY_LSUIElement = YES` → no Dock icon, not openable as a window from
  Finder/Spotlight/Launchpad. It lives only in the menu bar.
- All section UIs are already reusable SwiftUI views (`HomeView`, `EqualizerView`,
  `ControlsView`, `ControlsDetailView`, `SettingsView`, `FindMyBudsView`,
  `EarTipTestView`, `CaseLEDView`, `DiscoverView`, `ConnectView`, …) driven by
  shared `@StateObject`s (`Store`, `MainViewViewModel`, `BudsPickerComponentViewModel`).

The user wants a **dedicated, openable, more detailed window** in addition to the
menu-bar quick access.

## 2. Goal

Add a **dedicated main window** (sidebar + detail) that opens like a normal Mac app,
**while keeping** the existing menu-bar quick access. Hybrid model. Reuse existing
section views in v1; no rewrite of device logic.

## 3. Scope

### In scope
- A second SwiftUI scene: `WindowGroup` containing a new `MainWindowView`.
- `LSUIElement = NO` → Dock icon; openable from Launchpad/Spotlight/Applications.
- `MainWindowView` = `NavigationSplitView` (sidebar + detail).
- Sidebar sections: **Home** (device + battery + ANC), **Equalizer**, **Controls**,
  **Gestures**, **Find My Buds**, **Settings**. Connection status + L/R/Case battery
  shown in the sidebar footer.
- Detail pane **reuses the existing section views**, adapted to fill the larger width.
- Shared state: the App's existing `@StateObject`s are injected into BOTH scenes →
  one source of truth (menu bar and window stay in sync).
- Window/lifecycle behavior (see §5).

### Out of scope (explicit follow-ups)
- New device features / protocol changes.
- Deep per-section visual redesign for large sizes (v1 reuses; polish later).
- Localization.
- Replacing or removing the menu-bar scene.

## 4. Architecture

```
Nothing_X_MacOSApp (App)
├── @StateObject store, viewModel, budsPickerViewModel   (single shared instances)
├── Scene: MenuBarExtra  { … existing NavigationStack … }   ← unchanged
└── Scene: WindowGroup("Nothing X", id: "main")
        MainWindowView()
            .environmentObject(store / viewModel / budsPickerViewModel)
```

- Both scenes receive the **same** environment objects, so toggling ANC/EQ in one is
  reflected in the other.
- `MainWindowView`:
  ```
  NavigationSplitView {
      Sidebar(selection: $section)          // List of MainSection, footer = battery/status
  } detail: {
      switch section { … existing section views … }
  }
  ```
- `MainSection`: an enum (`home, equalizer, controls, gestures, findMyBuds, settings`)
  driving sidebar selection and the detail switch. This is window-local navigation
  state (separate from the menu bar's `MainViewViewModel.navigationPath`, which keeps
  driving the popover).

## 5. Behavior

- **Open:** Dock icon, Launchpad/Spotlight, or a new "Open Window" item in the
  menu-bar popover. `LSUIElement = NO`, default activation policy `.regular`.
- **Close window (red button / ⌘W):** app keeps running in the menu bar (does NOT
  quit). Reopening the Dock icon (or the menu-bar "Open Window" item) shows it again.
- **Quit:** ⌘Q / the existing Quit button terminates the app.
- **No device connected:** the window shows the same discover/connect flow the popover
  uses (reuse `DiscoverView`/`ConnectView`), so the window is useful before pairing.

## 6. Reuse strategy

v1 places the existing section views directly in the detail pane. Some are sized for
250px; where a view hard-codes a narrow width/frame it will be relaxed to fit the
detail pane (remove fixed `.frame(width:)` or wrap in a flexible container) — minimal,
per-view tweaks, not redesigns. Anything that needs real redesign for large sizes is
logged as a follow-up rather than done now.

## 7. Verification

Xcode is available locally, so this is verified by building and running:
1. `xcodebuild … build` → BUILD SUCCEEDED.
2. Launch the app: a Dock icon appears; the main window opens with the sidebar.
3. Navigate every sidebar section; confirm each detail view renders.
4. Change a setting in the window and confirm the menu-bar popover reflects it (shared
   state), and vice-versa.
5. Close the window → app stays in menu bar; reopen from Dock → window returns.
6. ⌘Q quits.

Protocol/device logic is already covered by the `NothingProtocol` package tests; this
work is UI-only.

## 8. Risks & mitigations

- **Two scenes sharing state:** `@StateObject` on the App struct are created once and
  shared via environment — correct by construction. Verified by the cross-reflection
  test (§7.4).
- **Narrow-sized views looking cramped in a wide detail pane:** accepted for v1
  (reuse-first); per-section polish is a follow-up. Relax obvious fixed frames only.
- **Window/quit semantics:** closing the window must not quit the app. If default
  behavior quits (it shouldn't with the menu-bar scene present), handle via an
  `NSApplicationDelegateAdaptor` returning `false` from
  `applicationShouldTerminateAfterLastWindowClosed`.
- **Dock-icon reopen:** ensure clicking the Dock icon with no open window reopens the
  main window (handle `applicationShouldHandleReopen` if needed).

## 9. Follow-ups (after v1)
- Per-section layout polish for large window sizes.
- Optional: remember window size/position; multiple-window behavior.
- Localization; app icon/branding review.
