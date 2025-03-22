import SwiftUI

struct NewsFeedView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @EnvironmentObject private var newsService: NewsService
    
    @State private var showCountrySelector = false
    @State private var showInterestSelector = false
    @State private var showSourcesSelector = false
    @State private var refreshing = false
    @State private var lastRefreshTime = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                PullToRefresh(isRefreshing: $refreshing) {
                    refreshNews()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Top Headlines")
                                .font(.system(size: userSettings.fontSize.headlineSize))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showCountrySelector = true
                            }) {
                                HStack {
                                    Text(getCountryEmoji(for: userSettings.selectedCountry.id))
                                    Text(userSettings.selectedCountry.name)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(userSettings.appTheme.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Last updated: \(formatRefreshTime(lastRefreshTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Top Headlines
                    if newsService.isLoadingTopHeadlines {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let error = newsService.topHeadlinesError {
                        ErrorView(error: error) {
                            newsService.fetchTopHeadlines(country: userSettings.selectedCountry.id)
                        }
                    } else if newsService.topHeadlines.isEmpty {
                        EmptyStateView(message: "No headlines available")
                    } else {
                        // Featured article
                        if let featuredArticle = newsService.topHeadlines.first {
                            NavigationLink(destination: ArticleDetailView(article: featuredArticle)) {
                                FeaturedArticleView(article: featuredArticle)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Trending topics
                        TrendingTopicsView(newsService: newsService)
                            .padding(.vertical, 8)
                        
                        // Rest of top headlines
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(newsService.topHeadlines.dropFirst().prefix(5), id: \.id) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    ArticleRowView(article: article, isRead: userSettings.isArticleRead(article))
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Personalized news section
                    if !userSettings.interests.isEmpty {
                        personalizedNewsSection
                    } else {
                        interestPromptSection
                    }
                    
                    // Category sections
                    categorySections
                }
                .padding(.top)
            }
            .navigationTitle("Rishi News")
            .navigationBarItems(
                leading: Button(action: {
                    showSourcesSelector = true
                }) {
                    Image(systemName: "newspaper")
                },
                trailing: HStack {
                    Button(action: {
                        showInterestSelector = true
                    }) {
                        Image(systemName: "star")
                    }
                    
                    Button(action: {
                        refreshNews()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            )
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector()
            }
            .sheet(isPresented: $showInterestSelector) {
                InterestSelectorView(isPresented: $showInterestSelector)
            }
            .sheet(isPresented: $showSourcesSelector) {
                NewsSourcesView()
            }
        }
    }
    
    private var personalizedNewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("For You")
                    .font(.system(size: userSettings.fontSize.headlineSize))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showInterestSelector = true
                }) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(userSettings.appTheme.accentColor)
                }
            }
            .padding(.horizontal)
            
            if newsService.isLoadingPersonalizedNews {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = newsService.personalizedNewsError {
                ErrorView(error: error) {
                    newsService.fetchPersonalizedNews(interests: userSettings.interests)
                }
            } else if newsService.personalizedNews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No personalized news found")
                        .font(.headline)
                    
                    Text("Try selecting different interests")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showInterestSelector = true
                    }) {
                        Text("Modify Interests")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(userSettings.appTheme.accentColor)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(newsService.personalizedNews.prefix(10), id: \.id) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                PersonalizedArticleCard(article: article)
                                    .frame(width: 250)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var interestPromptSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("Personalized News")
                .font(.headline)
            
            Text("Select your interests to see personalized news")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showInterestSelector = true
            }) {
                Text("Select Interests")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(userSettings.appTheme.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var categorySections: some View {
        VStack(spacing: 16) {
            // Guardian News Section
            guardianNewsSection
            
            ForEach(getVisibleCategories(), id: \.self) { category in
                CategoryNewsSection(category: category, newsService: newsService)
            }
        }
    }
    
    // Guardian News Section
    private var guardianNewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("The Guardian")
                    .font(.system(size: userSettings.fontSize.headlineSize))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    newsService.fetchGuardianArticles(section: "world")
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(userSettings.appTheme.accentColor)
                }
            }
            .padding(.horizontal)
            
            if newsService.categoryNews["guardian"] == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onAppear {
                        newsService.fetchGuardianArticles(section: "world")
                    }
            } else if newsService.categoryNews["guardian"]?.isEmpty ?? true {
                EmptyStateView(message: "No Guardian news available")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(newsService.categoryNews["guardian"] ?? [], id: \.id) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                CategoryArticleCard(article: article)
                                    .frame(width: 250)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func refreshNews() {
        refreshing = true
        lastRefreshTime = Date()
        
        // Fetch top headlines
        newsService.fetchTopHeadlines(country: userSettings.selectedCountry.id)
        
        // Fetch personalized news if there are interests
        if !userSettings.interests.isEmpty {
            newsService.fetchPersonalizedNews(interests: userSettings.interests)
        }
        
        // Fetch Guardian news
        newsService.fetchGuardianArticles(section: "world")
        
        // Fetch category news for visible categories
        for category in getVisibleCategories() {
            newsService.fetchCategoryNews(category: category, country: userSettings.selectedCountry.id)
        }
        
        // Reset refreshing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            refreshing = false
        }
    }
    
    private func getVisibleCategories() -> [String] {
        return userSettings.showCategories
            .filter { $0.value }
            .map { $0.key }
            .sorted()
    }
    
    private func getCountryEmoji(for countryCode: String) -> String {
        let base = UnicodeScalar("🇦").value - UnicodeScalar("a").value
        
        let firstChar = UnicodeScalar(base + UnicodeScalar(countryCode.prefix(1).lowercased())!.value)!
        let secondChar = UnicodeScalar(base + UnicodeScalar(countryCode.suffix(1).lowercased())!.value)!
        
        return String(firstChar) + String(secondChar)
    }
    
    private func formatRefreshTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FeaturedArticleView: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(12)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                                    startPoint: .bottom,
                                    endPoint: .center
                                )
                                .cornerRadius(12)
                            )
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(12)
                    }
                }
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        
                        Text(article.title)
                            .font(.system(size: userSettings.fontSize.headlineSize))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .shadow(radius: 2)
                        
                        HStack {
                            Text(article.source.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            if userSettings.isArticleRead(article) {
                                Text("Read")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.6))
                                    .cornerRadius(4)
                            } else {
                                Text("\(article.readingTime) min read")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    , alignment: .bottomLeading
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.system(size: userSettings.fontSize.headlineSize))
                        .fontWeight(.bold)
                        .lineLimit(3)
                    
                    HStack {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if userSettings.isArticleRead(article) {
                            Text("Read")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.6))
                                .cornerRadius(4)
                        } else {
                            Text("\(article.readingTime) min read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let description = article.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
        }
    }
}

struct PersonalizedArticleCard: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fill)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(article.title)
                .font(.system(size: userSettings.fontSize.textSize))
                .fontWeight(.semibold)
                .lineLimit(3)
                .foregroundColor(userSettings.isArticleRead(article) ? .gray : .primary)
            
            HStack {
                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(article.readingTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct CategoryNewsSection: View {
    let category: String
    @ObservedObject var newsService: NewsService
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.capitalized)
                .font(.system(size: userSettings.fontSize.headlineSize))
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if newsService.isLoadingCategoryNews {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if newsService.categoryNewsError != nil {
                ErrorView(error: newsService.categoryNewsError!) {
                    newsService.fetchCategoryNews(category: category, country: userSettings.selectedCountry.id)
                }
            } else if newsService.categoryNews[category]?.isEmpty ?? true {
                // Fetch if empty
                EmptyStateView(message: "No \(category) news available")
                    .onAppear {
                        if newsService.categoryNews[category] == nil {
                            newsService.fetchCategoryNews(category: category, country: userSettings.selectedCountry.id)
                        }
                    }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(newsService.categoryNews[category] ?? [], id: \.id) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                CategoryArticleCard(article: article)
                                    .frame(width: 250)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CategoryArticleCard: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .cornerRadius(8)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fill)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(article.title)
                .font(.system(size: userSettings.fontSize.textSize))
                .fontWeight(.semibold)
                .lineLimit(3)
                .foregroundColor(userSettings.isArticleRead(article) ? .gray : .primary)
            
            HStack {
                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if userSettings.isArticleRead(article) {
                    Text("Read")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Label("\(article.readingTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error loading content")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PullToRefresh: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            if offset > 0 || isRefreshing {
                ProgressView()
                    .frame(width: geometry.size.width, height: min(offset, 100))
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: OffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
            }
        )
        .onPreferenceChange(OffsetPreferenceKey.self) { value in
            offset = value
            
            if value > 100 && !isRefreshing {
                isRefreshing = true
                action()
            }
        }
        .frame(height: isRefreshing ? 100 : 0)
    }
}

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
