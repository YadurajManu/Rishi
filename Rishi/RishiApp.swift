//
//  RishiApp.swift
//  Rishi
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

@main
struct RishiApp: App {
    @StateObject private var userSettings = UserSettings()
    
    // Register app defaults
    init() {
        registerDefaults()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
    }
    
    private func registerDefaults() {
        // Register default values for user defaults
        UserDefaults.standard.register(defaults: [
            "darkMode": false,
            "onboardingComplete": false,
            "notificationsEnabled": true,
            "fontSize": 1 // medium
        ])
    }
}
