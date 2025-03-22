import SwiftUI

struct NewsSourcesView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var isAddingSource = false
    @State private var searchText = ""
    
    // Hard-coded list of well-known news sources
    // This would ideally come from an API in a real app
    private let availableSources: [NewsSource] = [
        NewsSource(id: "bbc-news", name: "BBC News", category: "general", country: "gb", language: "en"),
        NewsSource(id: "cnn", name: "CNN", category: "general", country: "us", language: "en"),
        NewsSource(id: "the-hindu", name: "The Hindu", category: "general", country: "in", language: "en"),
        NewsSource(id: "the-times-of-india", name: "The Times of India", category: "general", country: "in", language: "en"),
        NewsSource(id: "google-news-in", name: "Google News (India)", category: "general", country: "in", language: "en"),
        NewsSource(id: "the-economic-times", name: "The Economic Times", category: "business", country: "in", language: "en"),
        NewsSource(id: "the-guardian", name: "The Guardian", category: "general", country: "gb", language: "en"),
        NewsSource(id: "al-jazeera-english", name: "Al Jazeera English", category: "general", country: "qa", language: "en"),
        NewsSource(id: "reuters", name: "Reuters", category: "general", country: "us", language: "en"),
        NewsSource(id: "bloomberg", name: "Bloomberg", category: "business", country: "us", language: "en"),
        NewsSource(id: "espn", name: "ESPN", category: "sports", country: "us", language: "en"),
        NewsSource(id: "techcrunch", name: "TechCrunch", category: "technology", country: "us", language: "en"),
        NewsSource(id: "wired", name: "Wired", category: "technology", country: "us", language: "en"),
        NewsSource(id: "national-geographic", name: "National Geographic", category: "science", country: "us", language: "en"),
        NewsSource(id: "the-verge", name: "The Verge", category: "technology", country: "us", language: "en"),
        NewsSource(id: "bbc-sport", name: "BBC Sport", category: "sports", country: "gb", language: "en"),
        NewsSource(id: "financial-times", name: "Financial Times", category: "business", country: "gb", language: "en"),
        NewsSource(id: "the-washington-post", name: "The Washington Post", category: "general", country: "us", language: "en"),
        NewsSource(id: "the-wall-street-journal", name: "The Wall Street Journal", category: "business", country: "us", language: "en"),
        NewsSource(id: "ndtv", name: "NDTV", category: "general", country: "in", language: "en")
    ]
    
    private var filteredSources: [NewsSource] {
        if searchText.isEmpty {
            return availableSources
        } else {
            return availableSources.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.category.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search sources", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Selected sources
                if !userSettings.preferredSources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Sources")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    userSettings.clearAllSources()
                                }
                            }) {
                                Text("Clear All")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(userSettings.preferredSources, id: \.id) { source in
                                    Button(action: {
                                        withAnimation {
                                            userSettings.toggleSource(source)
                                        }
                                    }) {
                                        HStack {
                                            Text(source.name)
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(getColorForCategory(source.category))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Available sources list
                List {
                    ForEach(filteredSources) { source in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(source.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text(source.category.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(getColorForCategory(source.category).opacity(0.2))
                                        .foregroundColor(getColorForCategory(source.category))
                                        .cornerRadius(4)
                                    
                                    Text(countryFlag(for: source.country))
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    userSettings.toggleSource(source)
                                }
                            }) {
                                Image(systemName: userSettings.isSourceSelected(source) ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundColor(userSettings.isSourceSelected(source) ? .green : .blue)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("News Sources")
        }
    }
    
    // Helper function to get color based on category
    private func getColorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "business":
            return .blue
        case "entertainment":
            return .purple
        case "general":
            return .gray
        case "health":
            return .green
        case "science":
            return .orange
        case "sports":
            return .red
        case "technology":
            return .indigo
        default:
            return .gray
        }
    }
    
    // Helper function to get flag emoji for country code
    private func countryFlag(for countryCode: String) -> String {
        let base = UnicodeScalar("🇦").value - UnicodeScalar("a").value
        
        let firstChar = UnicodeScalar(base + UnicodeScalar(countryCode.prefix(1).lowercased())!.value)!
        let secondChar = UnicodeScalar(base + UnicodeScalar(countryCode.suffix(1).lowercased())!.value)!
        
        return String(firstChar) + String(secondChar)
    }
}

// Data model for news sources
struct NewsSource: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String
    let country: String
    let language: String
    
    static func == (lhs: NewsSource, rhs: NewsSource) -> Bool {
        return lhs.id == rhs.id
    }
}

struct NewsSourcesView_Previews: PreviewProvider {
    static var previews: some View {
        NewsSourcesView()
            .environmentObject(UserSettings())
    }
} 