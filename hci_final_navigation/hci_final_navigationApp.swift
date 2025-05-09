//
//  hci_final_navigationApp.swift
//  hci_final_navigation
//
//  Created by 刘唯琛 on 2025/5/9.
//

import SwiftUI
import GoogleMaps

@main
struct hci_final_navigationApp: App {
    init() {
        GMSServices.provideAPIKey("AIzaSyDUyaBMHtEylY8CiuRNSabK8yP5GbFULOg")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
