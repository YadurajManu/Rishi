import SwiftUI

struct TrendingTopicsView: View {
    @ObservedObject var newsService: NewsService
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var selectedTopic: String? = nil
    @State private var showSearchResults = false
    @State private var searchTopic: String = ""
    
    let maxTopicsToShow = 5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending Topics")
                .font(.system(size: userSettings.fontSize.headlineSize))
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if newsService.trendingTopics.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(newsService.trendingTopics.prefix(maxTopicsToShow), id: \.self) { topic in
                            Button(action: {
                                selectedTopic = topic
                                searchTopic = topic
                                showSearchResults = true
                            }) {
                                Text(topic.capitalized)
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(userSettings.appTheme.accentColor.opacity(0.15))
                                    )
                                    .foregroundColor(userSettings.appTheme.accentColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showSearchResults) {
            NavigationView {
                SearchResultsView(query: searchTopic, newsService: newsService)
                    .navigationTitle("Results for '\(searchTopic)'")
                    .navigationBarItems(trailing: Button("Done") {
                        showSearchResults = false
                    })
            }
        }
    }
}

struct SearchResultsView: View {
    let query: String
    @ObservedObject var newsService: NewsService
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Searching...")
                    .onAppear {
                        newsService.searchNews(query: query)
                        // Simulate loading time if needed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                        }
                    }
            } else if let error = newsService.searchResultsError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Error loading results")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        isLoading = true
                        newsService.searchNews(query: query)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isLoading = false
                        }
                    }) {
                        Text("Try Again")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else if newsService.searchResults.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No results found")
                        .font(.headline)
                    
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(newsService.searchResults) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleRowView(article: article, isRead: userSettings.isArticleRead(article))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct ArticleRowView: View {
    let article: Article
    let isRead: Bool
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: userSettings.fontSize.textSize))
                    .fontWeight(.semibold)
                    .foregroundColor(isRead ? .gray : .primary)
                    .lineLimit(3)
                
                HStack {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let publishedAt = ISO8601DateFormatter().date(from: article.publishedAt) {
                        Text(relativeTime(from: publishedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("\(article.readingTime) min read", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isRead {
                        Text("Read")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to format relative time
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TrendingTopicsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingTopicsView(newsService: NewsService())
            .environmentObject(UserSettings())
    }
} 