//
//  ContentView.swift
//  Rishi
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @EnvironmentObject private var newsService: NewsService
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var showOnboarding = false
    
    @State private var autoRefreshTimer: Timer? = nil
    
    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(isPresented: $showOnboarding) {
                    onboardingComplete = true
                }
            } else {
                MainTabView()
                    .environmentObject(userSettings)
                    .environmentObject(newsService)
            }
        }
        .preferredColorScheme(userSettings.darkMode ? .dark : .light)
        .onAppear {
            if !onboardingComplete {
                showOnboarding = true
            }
            setupAutoRefresh()
        }
        .onChange(of: userSettings.autoRefreshInterval) { newValue in
            setupAutoRefresh()
        }
    }
    
    private func setupAutoRefresh() {
        // Cancel existing timer if any
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        
        // If auto-refresh is enabled (interval > 0), set up a new timer
        if userSettings.autoRefreshInterval > 0 {
            let interval = TimeInterval(userSettings.autoRefreshInterval * 60) // Convert minutes to seconds
            autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                // Refresh news data
                newsService.fetchTopHeadlines(country: userSettings.selectedCountry.id)
                
                if !userSettings.interests.isEmpty {
                    newsService.fetchPersonalizedNews(interests: userSettings.interests)
                }
                
                // Fetch Guardian news
                newsService.fetchGuardianArticles(section: "world")
                
                // Refresh category news for visible categories
                for (category, isVisible) in userSettings.showCategories {
                    if isVisible {
                        newsService.fetchCategoryNews(category: category, country: userSettings.selectedCountry.id)
                    }
                }
            }
        }
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(image: "globe.americas.fill", title: "World News", description: "Stay up to date with the latest news from around the world."),
        OnboardingPage(image: "globe.asia.australia.fill", title: "Regional News", description: "Get news specific to your region, including India, US, and many more."),
        OnboardingPage(image: "newspaper.fill", title: "Categories", description: "Browse news by categories like Business, Technology, and Entertainment."),
        OnboardingPage(image: "gear", title: "Customization", description: "Personalize your news experience with various settings and preferences.")
    ]
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].image)
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                                .padding()
                            
                            Text(pages[index].title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(pages[index].description)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

#Preview {
    ContentView()
}
