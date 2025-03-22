import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NewsFeedView()
                .tabItem {
                    Label("Top News", systemImage: "newspaper")
                }
                .tag(0)
            
            CategoryView()
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
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

struct CategoryView: View {
    let categories = [
        ("Business", "briefcase", Color.blue),
        ("Entertainment", "film", Color.purple),
        ("Health", "heart", Color.pink),
        ("Science", "flask.fill", Color.orange),
        ("Sports", "sportscourt", Color.green),
        ("Technology", "desktopcomputer", Color.indigo)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.0) { category, icon, color in
                    NavigationLink {
                        CategoryNewsView(category: category.lowercased())
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(color)
                                .cornerRadius(8)
                            
                            Text(category)
                                .font(.headline)
                                .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Categories")
        }
    }
}

struct CategoryNewsView: View {
    let category: String
    @StateObject private var viewModel = NewsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let errorMessage = viewModel.errorMessage {
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
        .onAppear {
            loadCategoryNews()
        }
    }
    
    private func loadCategoryNews() {
        viewModel.fetchNewsByCategory(category: category)
    }
}

struct BookmarksView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Bookmarks Coming Soon")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("You'll be able to save your favorite articles here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
            .navigationTitle("Bookmarks")
        }
    }
}

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
} 