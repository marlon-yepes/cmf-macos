//
//  Nothing_X_MacOSApp.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 07/01/23.
//

import SwiftUI


@main
struct Nothing_X_MacOSApp: App {
    @StateObject private var store = Store()
    @StateObject private var viewModel = MainViewViewModel(bluetoothService: BluetoothServiceImpl(), nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared)
    @StateObject private var budsPickerViewModel = BudsPickerComponentViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private var batteryText: String {
        guard let left = viewModel.leftBattery, let right = viewModel.rightBattery else {
            return ""
        }
        let l = Int(left)
        let r = Int(right)
        switch store.batteryDisplayMode {
        case .both:
            return l == r ? "\(l)%" : "\(l)·\(r)%"
        case .average:
            return "\((l + r) / 2)%"
        case .minimum:
            return "\(min(l, r))%"
        }
    }

    var body: some Scene {
        MenuBarExtra {
            NavigationStack(path: $viewModel.navigationPath.animation(.default)) {
                
                HomeView()
                    .navigationDestination(for: Destination.self) { destination in
                        DestinationView(destination: destination)
                        
                        
                    }
                    
            }
            .environmentObject(store)
            .environmentObject(viewModel)
            .environmentObject(budsPickerViewModel)
            .frame(width: 250, height: 230)
        
            
        } label: {
            
            Label(batteryText, image: "nothing.ear.1")
                .labelStyle(.titleAndIcon)

        }
        .menuBarExtraStyle(.window)

        WindowGroup("Nothing X", id: "main") {
            MainWindowView()
                .environmentObject(store)
                .environmentObject(viewModel)
                .environmentObject(budsPickerViewModel)
        }
        .windowResizability(.contentMinSize)

    }

}
