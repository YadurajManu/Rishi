import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NewsFeedView()
                .environmentObject(userSettings)
                .tabItem {
                    Label("Top News", systemImage: "newspaper")
                }
                .tag(0)
            
            CategoryView()
                .environmentObject(userSettings)
                .tabItem {
                    Label("Categories", systemImage: "list.bullet")
                }
                .tag(1)
            
            BookmarksView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                .tag(2)
            
            SettingsView()
                .environmentObject(userSettings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct CategoryView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showCountrySelector = false
    
    let categories = [
        ("Business", "briefcase", Color.blue),
        ("Entertainment", "film", Color.purple),
        ("Health", "heart", Color.pink),
        ("Science", "flask.fill", Color.orange),
        ("Sports", "sportscourt", Color.green),
        ("Technology", "desktopcomputer", Color.indigo),
        ("World", "globe", Color.teal),
        ("Politics", "building.columns", Color.red)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Country selector button
                Button(action: {
                    showCountrySelector = true
                }) {
                    HStack {
                        Text(userSettings.selectedCountry.flag)
                            .font(.title3)
                        
                        Text("News for \(userSettings.selectedCountry.name)")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                Divider()
                
                // Categories grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(categories, id: \.0) { category, icon, color in
                            NavigationLink {
                                CategoryNewsView(category: category.lowercased())
                                    .environmentObject(userSettings)
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(color)
                                        .cornerRadius(25)
                                    
                                    Text(category)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Categories")
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector(isPresented: $showCountrySelector)
                    .environmentObject(userSettings)
            }
        }
    }
}

struct CategoryNewsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    let category: String
    @StateObject private var viewModel: NewsViewModel
    @State private var showCountrySelector = false
    
    init(category: String) {
        self.category = category
        _viewModel = StateObject(wrappedValue: NewsViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Country selector button
            Button(action: {
                showCountrySelector = true
            }) {
                HStack {
                    Text(userSettings.selectedCountry.flag)
                        .font(.title3)
                    
                    Text("News for \(userSettings.selectedCountry.name)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            Divider()
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Spacer()
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Error loading news")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        loadCategoryNews()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            } else if viewModel.articles.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "newspaper")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No \(category.capitalized) news found")
                        .font(.headline)
                    
                    Text("Try selecting a different region")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Button(action: {
                        showCountrySelector = true
                    }) {
                        Text("Select Region")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.articles) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            ArticleCard(article: article)
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    loadCategoryNews()
                }
            }
        }
        .navigationTitle(category.capitalized)
        .sheet(isPresented: $showCountrySelector) {
            CountrySelector(isPresented: $showCountrySelector)
                .environmentObject(userSettings)
        }
        .onAppear {
            // Create new viewModel with correct settings
            let newViewModel = NewsViewModel(userSettings: userSettings)
            
            // Use reflection to set the StateObject
            if let mirror = Mirror(reflecting: _viewModel).children.first,
               let binding = mirror.value as? ReferenceWritableKeyPath<CategoryNewsView, NewsViewModel> {
                self[keyPath: binding] = newViewModel
            }
            
            loadCategoryNews()
        }
    }
    
    private func loadCategoryNews() {
        viewModel.fetchNewsByCategory(category: category)
    }
}

struct BookmarksView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var itemToShare: URL?
    
    var filteredBookmarks: [Article] {
        if searchText.isEmpty {
            return userSettings.bookmarkedArticles
        } else {
            return userSettings.bookmarkedArticles.filter { article in
                article.title.lowercased().contains(searchText.lowercased()) ||
                (article.description?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search bookmarks", text: $searchText)
                    
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
                
                if filteredBookmarks.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        if searchText.isEmpty {
                            Text("No Bookmarks Yet")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Save articles to read later by tapping the bookmark icon")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        } else {
                            Text("No Matching Bookmarks")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Try another search term")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredBookmarks) { article in
                            BookmarkedArticleRow(article: article, onShare: {
                                itemToShare = URL(string: article.url)
                                showShareSheet = true
                            }, onRemove: {
                                userSettings.toggleBookmark(for: article)
                            })
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                userSettings.toggleBookmark(for: filteredBookmarks[index])
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Bookmarks")
            .sheet(isPresented: $showShareSheet) {
                if let url = itemToShare {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

struct BookmarkedArticleRow: View {
    let article: Article
    let onShare: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article)) {
            HStack(alignment: .center, spacing: 12) {
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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(formattedDate(from: article.publishedAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: onRemove) {
                            Image(systemName: "bookmark.slash.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
}

struct SettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showCountrySelector = false
    @State private var showInterestsSelector = false
    
    let refreshOptions = [
        (0, "Off"),
        (15, "15 minutes"),
        (30, "30 minutes"),
        (60, "1 hour"),
        (120, "2 hours")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Region")) {
                    Button(action: {
                        showCountrySelector = true
                    }) {
                        HStack {
                            Text("News Region")
                            
                            Spacer()
                            
                            Text("\(userSettings.selectedCountry.flag) \(userSettings.selectedCountry.name)")
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Personalization")) {
                    NavigationLink(destination: InterestSelectorView(isPresented: $showInterestsSelector)) {
                        HStack {
                            Text("Interests")
                            
                            Spacer()
                            
                            if userSettings.interests.isEmpty {
                                Text("None selected")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(userSettings.interests.count) selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Picker("Auto Refresh", selection: $userSettings.autoRefreshInterval) {
                        ForEach(refreshOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $userSettings.darkMode)
                    
                    Picker("Font Size", selection: $userSettings.fontSize) {
                        ForEach(UserSettings.FontSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $userSettings.notificationsEnabled)
                    
                    if userSettings.notificationsEnabled {
                        NavigationLink(destination: NotificationSettingsView()) {
                            Text("Notification Settings")
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector(isPresented: $showCountrySelector)
                    .environmentObject(userSettings)
            }
            .sheet(isPresented: $showInterestsSelector) {
                InterestSelectorView(isPresented: $showInterestsSelector)
                    .environmentObject(userSettings)
            }
        }
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        List {
            Section(header: Text("Notification Types")) {
                ForEach(userSettings.getAllCategories(), id: \.self) { category in
                    Toggle(category.capitalized, isOn: Binding(
                        get: { userSettings.showCategories[category] ?? true },
                        set: { userSettings.showCategories[category] = $0 }
                    ))
                }
            }
            
            Section(header: Text("Breaking News")) {
                Toggle("Breaking News Alerts", isOn: .constant(true))
                    .tint(.red)
            }
            
            Section(header: Text("Personalized Updates")) {
                Toggle("Interest-based Alerts", isOn: .constant(true))
                Text("Receive notifications about news related to your selected interests")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Quiet Hours")) {
                Toggle("Enable Quiet Hours", isOn: .constant(false))
                
                HStack {
                    Text("From")
                    Spacer()
                    Text("10:00 PM")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("To")
                    Spacer()
                    Text("7:00 AM")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Notification Settings")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text("User Data Storage")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("We store user credentials, preferences, and settings using secure methods, in accordance with our Privacy Policy.")
                }
                
                Group {
                    Text("Location Data Collection")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("We use location data only to provide region-specific news. Your location data is not stored or shared with third parties.")
                }
                
                Group {
                    Text("Third-Party Services")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Rishi News uses NewsData.io for news content. Their privacy policies may affect how your data is handled when accessing their content.")
                }
                
                Group {
                    Text("Data Protection")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("We do not sell, purchase, or engage in commercial activities with user data. Your data is used only to enhance your news reading experience.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text("Content Usage")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("News content is provided for personal, non-commercial use only. Redistribution or commercial use is prohibited without express permission.")
                }
                
                Group {
                    Text("Accuracy and Liability")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("While we strive for accuracy, we cannot guarantee the completeness or timeliness of news. Rishi News is not liable for decisions made based on content provided.")
                }
                
                Group {
                    Text("Intellectual Property")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("All content, design, and functionality of Rishi News are protected by intellectual property laws and belong to their respective owners.")
                }
                
                Group {
                    Text("Modifications")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("We reserve the right to modify these terms at any time. Continued use after changes constitutes acceptance of the new terms.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
} 