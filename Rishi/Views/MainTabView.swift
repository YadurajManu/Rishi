import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NewsFeedView()
                .environmentObject(userSettings)
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
                .tag(Tab.news)
            
            BookmarksView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                .tag(Tab.bookmarks)
            
            ReadingHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(Tab.history)
            
            SettingsView()
                .environmentObject(userSettings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .accentColor(userSettings.appTheme.accentColor)
        .environmentObject(userSettings)
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
    @State private var sortOption = SortOption.newest
    @State private var isGridView = false
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case source = "Source"
        case title = "Title"
    }
    
    var filteredBookmarks: [Article] {
        var bookmarks = userSettings.bookmarkedArticles
        
        // Apply search filter
        if !searchText.isEmpty {
            bookmarks = bookmarks.filter { article in
                article.title.lowercased().contains(searchText.lowercased()) ||
                (article.description?.lowercased().contains(searchText.lowercased()) ?? false) ||
                article.source.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            bookmarks.sort { (a, b) -> Bool in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                
                if let dateA = dateFormatter.date(from: a.publishedAt),
                   let dateB = dateFormatter.date(from: b.publishedAt) {
                    return dateA > dateB
                }
                return false
            }
        case .oldest:
            bookmarks.sort { (a, b) -> Bool in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                
                if let dateA = dateFormatter.date(from: a.publishedAt),
                   let dateB = dateFormatter.date(from: b.publishedAt) {
                    return dateA < dateB
                }
                return false
            }
        case .source:
            bookmarks.sort { (a, b) -> Bool in
                a.source.name < b.source.name
            }
        case .title:
            bookmarks.sort { (a, b) -> Bool in
                a.title < b.title
            }
        }
        
        return bookmarks
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
                
                // Sort and View type controls
                HStack {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                            }) {
                                Label(option.rawValue, systemImage: option == sortOption ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text(sortOption.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isGridView.toggle()
                        }
                    }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
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
                    if isGridView {
                        gridView
                    } else {
                        listView
                    }
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
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredBookmarks) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        BookmarkGridItem(article: article)
                            .frame(height: 220)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(filteredBookmarks) { article in
                BookmarkedArticleRow(article: article, onShare: {
                    itemToShare = URL(string: article.url)
                    showShareSheet = true
                }, onRemove: {
                    userSettings.removeBookmark(article)
                })
            }
            .onDelete { indexSet in
                for index in indexSet {
                    userSettings.removeBookmark(filteredBookmarks[index])
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct BookmarkGridItem: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 110)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 110)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 110)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                            .cornerRadius(8)
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 110)
                            .cornerRadius(8)
                    }
                }
                .overlay(
                    Text(article.source.name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(6),
                    alignment: .bottomLeading
                )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 110)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    )
            }
            
            // Title
            Text(article.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Date
            HStack {
                Text(formattedDate(from: article.publishedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
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
    @State private var showRestartAlert = false
    
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
                // App appearance section
                Section(header: Text("Appearance")) {
                    // Theme picker
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Label {
                                Text("App Theme")
                            } icon: {
                                Image(systemName: "paintpalette")
                                    .foregroundColor(userSettings.appTheme.accentColor)
                            }
                            
                            Spacer()
                            
                            Text(userSettings.appTheme.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Dark mode toggle
                    Toggle(isOn: $userSettings.darkMode) {
                        Label {
                            Text("Dark Mode")
                        } icon: {
                            Image(systemName: userSettings.darkMode ? "moon.fill" : "moon")
                                .foregroundColor(userSettings.darkMode ? .purple : .primary)
                        }
                    }
                    
                    // Font size picker
                    Picker("Font Size", selection: $userSettings.fontSize) {
                        ForEach(UserSettings.FontSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    }
                }
                
                // Region section
                Section(header: Text("Region")) {
                    Button(action: {
                        showCountrySelector = true
                    }) {
                        HStack {
                            Label {
                                Text("News Region")
                            } icon: {
                                Text(userSettings.selectedCountry.flag)
                                    .font(.title3)
                            }
                            
                            Spacer()
                            
                            Text(userSettings.selectedCountry.name)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Personalization section
                Section(header: Text("Personalization")) {
                    NavigationLink(destination: InterestSelectorView(isPresented: $showInterestsSelector)) {
                        HStack {
                            Label {
                                Text("Interests")
                            } icon: {
                                Image(systemName: "star")
                                    .foregroundColor(.yellow)
                            }
                            
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
                
                // Notifications section
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $userSettings.notificationsEnabled) {
                        Label {
                            Text("Enable Notifications")
                        } icon: {
                            Image(systemName: userSettings.notificationsEnabled ? "bell.fill" : "bell")
                                .foregroundColor(userSettings.notificationsEnabled ? .red : .primary)
                        }
                    }
                    
                    if userSettings.notificationsEnabled {
                        NavigationLink(destination: NotificationSettingsView()) {
                            Label {
                                Text("Notification Categories")
                            } icon: {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Data section
                Section(header: Text("Data Management")) {
                    Button(action: {
                        withAnimation {
                            userSettings.clearReadingHistory()
                        }
                    }) {
                        Label {
                            Text("Clear Reading History")
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(userSettings.readingHistory.isEmpty)
                    
                    Toggle(isOn: .constant(true)) {
                        Label {
                            Text("Data Saver")
                        } icon: {
                            Image(systemName: "speedometer")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Label {
                            Text("Version")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy would go here").padding()) {
                        Label {
                            Text("Privacy Policy")
                        } icon: {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    NavigationLink(destination: Text("Terms of Service would go here").padding()) {
                        Label {
                            Text("Terms of Service")
                        } icon: {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector(isPresented: $showCountrySelector)
                    .environmentObject(userSettings)
            }
            .sheet(isPresented: $showInterestsSelector) {
                InterestSelectorView(isPresented: $showInterestsSelector)
                    .environmentObject(userSettings)
            }
            .alert(isPresented: $showRestartAlert) {
                Alert(
                    title: Text("Restart Required"),
                    message: Text("Please restart the app for the theme changes to take full effect."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct ThemeSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTheme: UserSettings.AppTheme
    
    init() {
        // Initialize selectedTheme from userSettings
        _selectedTheme = State(initialValue: UserSettings().appTheme)
    }
    
    var body: some View {
        List {
            ForEach(UserSettings.AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    selectedTheme = theme
                    userSettings.appTheme = theme
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(theme.backgroundColor)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(theme.accentColor, lineWidth: 2)
                                )
                            
                            if theme == selectedTheme {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 18, height: 18)
                            }
                        }
                        
                        Text(theme.title)
                            .padding(.leading, 10)
                        
                        Spacer()
                        
                        if theme == selectedTheme {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                .onAppear {
                    selectedTheme = userSettings.appTheme
                }
            }
        }
        .navigationTitle("App Theme")
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

struct ReadingHistoryView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showShareSheet = false
    @State private var itemToShare: URL?
    @State private var searchText = ""
    @State private var selectedTimeFilter = "All Time"
    
    let timeFilters = ["Today", "This Week", "This Month", "All Time"]
    
    var filteredHistory: [UserSettings.ReadHistoryItem] {
        let calendar = Calendar.current
        let now = Date()
        
        var filtered = userSettings.readingHistory
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.article.title.lowercased().contains(searchText.lowercased()) ||
                item.article.description?.lowercased().contains(searchText.lowercased()) ?? false ||
                item.article.source.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply time filter
        switch selectedTimeFilter {
        case "Today":
            filtered = filtered.filter { calendar.isDateInToday($0.timestamp) }
        case "This Week":
            filtered = filtered.filter {
                let components = calendar.dateComponents([.weekOfYear], from: $0.timestamp, to: now)
                return components.weekOfYear == 0
            }
        case "This Month":
            filtered = filtered.filter {
                let components = calendar.dateComponents([.month], from: $0.timestamp, to: now)
                return components.month == 0
            }
        default:
            // All time - no additional filtering
            break
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search history", text: $searchText)
                    
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
                
                // Time filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(timeFilters, id: \.self) { filter in
                            Button(action: {
                                selectedTimeFilter = filter
                            }) {
                                Text(filter)
                                    .font(.caption)
                                    .fontWeight(selectedTimeFilter == filter ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedTimeFilter == filter ?
                                        userSettings.appTheme.accentColor :
                                        Color(.systemGray6)
                                    )
                                    .foregroundColor(
                                        selectedTimeFilter == filter ?
                                        .white :
                                        .primary
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if filteredHistory.isEmpty {
                    emptyHistoryView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Reading History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            userSettings.clearReadingHistory()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(userSettings.readingHistory.isEmpty)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = itemToShare {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Reading History")
                .font(.headline)
            
            Text("Articles you read will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: NewsFeedView()) {
                Text("Browse News")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(userSettings.appTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var historyListView: some View {
        List {
            ForEach(filteredHistory) { item in
                NavigationLink(destination: ArticleDetailView(article: item.article)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.article.source.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatDate(item.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(item.article.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(relativeTime(from: item.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                itemToShare = URL(string: item.article.url)
                                showShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                if userSettings.isArticleBookmarked(item.article) {
                                    userSettings.removeBookmark(item.article)
                                } else {
                                    userSettings.addBookmark(item.article)
                                }
                            }) {
                                Image(systemName: userSettings.isArticleBookmarked(item.article) ? "bookmark.fill" : "bookmark")
                                    .font(.caption)
                                    .foregroundColor(userSettings.isArticleBookmarked(item.article) ? .yellow : .blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum Tab {
    case news
    case bookmarks
    case history
    case settings
} 