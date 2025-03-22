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
    @StateObject private var newsService = NewsService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Register app defaults
    init() {
        registerDefaults()
    }
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(isOnboarding: $hasCompletedOnboarding)
                    .environmentObject(userSettings)
            } else {
                ContentView()
                    .environmentObject(userSettings)
                    .environmentObject(newsService)
                    .preferredColorScheme(getColorScheme())
                    .accentColor(userSettings.appTheme.accentColor)
                    .onAppear {
                        // Fetch initial data
                        newsService.fetchTopHeadlines(country: userSettings.selectedCountry.id)
                        
                        // If user has interests, fetch personalized news
                        if !userSettings.interests.isEmpty {
                            newsService.fetchPersonalizedNews(interests: userSettings.interests)
                        }
                        
                        // Fetch Guardian news
                        newsService.fetchGuardianArticles(section: "world")
                    }
            }
        }
    }
    
    private func registerDefaults() {
        // Register default values for user defaults
        UserDefaults.standard.register(defaults: [
            "darkMode": false,
            "notificationsEnabled": false,
            "fontSize": 1, // Medium
            "userCountryCode": "in", // India as default
            "hasCompletedOnboarding": false,
            "appTheme": 0, // System
            "autoRefreshInterval": 0 // Disabled
        ])
    }
    
    // Helper method to determine the color scheme based on user settings and app theme
    private func getColorScheme() -> ColorScheme? {
        if userSettings.appTheme == .system {
            return userSettings.darkMode ? .dark : .light
        } else if userSettings.appTheme == .dark {
            return .dark
        } else {
            return .light
        }
    }
}
