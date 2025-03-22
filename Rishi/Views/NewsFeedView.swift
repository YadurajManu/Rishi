import SwiftUI

struct NewsFeedView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var viewModel: NewsViewModel
    @StateObject private var weatherViewModel = WeatherViewModel()
    @State private var searchText = ""
    @State private var showCountrySelector = false
    @State private var showShareSheet = false
    @State private var itemToShare: URL?
    @State private var isRefreshing = false
    @State private var showInterestsSelector = false
    
    init() {
        // Will be updated in onAppear with userSettings
        _viewModel = StateObject(wrappedValue: NewsViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search news", text: $searchText)
                        .onSubmit {
                            viewModel.searchNews(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.fetchTopHeadlines()
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
                
                // Location selector and reload button
                HStack {
                    Button(action: {
                        showCountrySelector = true
                    }) {
                        HStack {
                            Text(userSettings.selectedCountry.flag)
                                .font(.title3)
                            
                            Text("News for \(userSettings.selectedCountry.name)")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
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
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isRefreshing = true
                            if searchText.isEmpty {
                                viewModel.fetchTopHeadlines()
                            } else {
                                viewModel.searchNews(query: searchText)
                            }
                            
                            // Update weather also
                            if let lat = userSettings.selectedCountry.id == "in" ? 28.6139 : 37.0902,
                               let lon = userSettings.selectedCountry.id == "in" ? 77.2090 : -95.7129 {
                                weatherViewModel.fetchWeather(lat: lat, lon: lon)
                            }
                            
                            // Auto reset the refreshing state after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRefreshing = false
                            }
                        }
                    }) {
                        Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .rotationEffect(isRefreshing ? .degrees(360) : .degrees(0))
                            .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Weather widget
                WeatherWidget(viewModel: weatherViewModel)
                    .environmentObject(userSettings)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                Divider()
                    .padding(.bottom, 5)
                
                // Content
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
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
                            .padding(.bottom, 4)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            if searchText.isEmpty {
                                viewModel.fetchTopHeadlines()
                            } else {
                                viewModel.searchNews(query: searchText)
                            }
                        }) {
                            Text("Try Again")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                    Spacer()
                } else if viewModel.articles.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "newspaper")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No news found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("Try another search term or region")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Text("Try selecting a different region")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
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
                    .padding()
                    Spacer()
                } else {
                    // Trending news section
                    if !viewModel.trendingArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Trending")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.trendingArticles) { article in
                                        TrendingArticleCard(article: article)
                                            .frame(width: 260, height: 280)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .frame(height: 300)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }
                    
                    // Main news feed
                    List {
                        if !searchText.isEmpty {
                            Text("Search results for \"\(searchText)\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 16)
                        } else {
                            // Last refresh time indicator
                            HStack {
                                Text(viewModel.getFormattedRefreshTime())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if !userSettings.interests.isEmpty {
                                    NavigationLink(destination: InterestSelectorView(isPresented: .constant(true))) {
                                        Text("Interests")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                            
                            // Personalized news section
                            if !userSettings.interests.isEmpty && !viewModel.personalizedArticles.isEmpty {
                                Section(header: 
                                    Text("Based on Your Interests")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.top, 16)
                                        .padding(.bottom, 8)
                                        .padding(.horizontal, 16)
                                ) {
                                    ForEach(viewModel.personalizedArticles.prefix(3)) { article in
                                        ArticleRowView(article: article, onShare: {
                                            itemToShare = URL(string: article.url)
                                            showShareSheet = true
                                        })
                                        .listRowInsets(EdgeInsets())
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                    
                                    if viewModel.personalizedArticles.count > 3 {
                                        NavigationLink(destination: PersonalizedNewsView()) {
                                            Text("See all personalized news")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    }
                                }
                                
                                Text("Top Headlines")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 16)
                            } else {
                                Text("Top Headlines")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        ForEach(viewModel.articles) { article in
                            ArticleRowView(article: article, onShare: {
                                itemToShare = URL(string: article.url)
                                showShareSheet = true
                            })
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                        
                        if userSettings.interests.isEmpty {
                            Button(action: {
                                showInterestsSelector = true
                            }) {
                                HStack {
                                    Image(systemName: "star")
                                        .foregroundColor(.yellow)
                                    Text("Personalize your news feed")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.7))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.refreshAllContent()
                    }
                }
            }
            .navigationTitle("Rishi News")
            .sheet(isPresented: $showCountrySelector) {
                CountrySelector(isPresented: $showCountrySelector)
                    .environmentObject(userSettings)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = itemToShare {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showInterestsSelector) {
                InterestSelectorView(isPresented: $showInterestsSelector)
                    .environmentObject(userSettings)
            }
            .onAppear {
                // Create new viewModel with correct settings when the view appears
                let newViewModel = NewsViewModel(userSettings: userSettings)
                
                // Use reflection to set the StateObject - hacky but works
                if let mirror = Mirror(reflecting: _viewModel).children.first,
                   let binding = mirror.value as? ReferenceWritableKeyPath<NewsFeedView, NewsViewModel> {
                    self[keyPath: binding] = newViewModel
                }
                
                // Fetch weather data
                if let lat = userSettings.selectedCountry.id == "in" ? 28.6139 : 37.0902,
                   let lon = userSettings.selectedCountry.id == "in" ? 77.2090 : -95.7129 {
                    weatherViewModel.fetchWeather(lat: lat, lon: lon)
                }
            }
            .onChange(of: userSettings.selectedCountry) { newCountry in
                if let lat = newCountry.id == "in" ? 28.6139 : 37.0902,
                   let lon = newCountry.id == "in" ? 77.2090 : -95.7129 {
                    weatherViewModel.fetchWeather(lat: lat, lon: lon)
                }
            }
        }
    }
}

struct ArticleRowView: View {
    let article: Article
    let onShare: () -> Void
    
    var body: some View {
        ZStack {
            NavigationLink {
                ArticleDetailView(article: article)
            } label: {
                ArticleCard(article: article)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add overlay buttons
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
                Spacer()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TrendingArticleCard: View {
    let article: Article

    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article)) {
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
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                                .cornerRadius(8)
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fill)
                                .cornerRadius(8)
                        }
                    }
                    .frame(height: 150)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "newspaper.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Trending")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonalizedNewsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var viewModel = NewsViewModel()
    @State private var showInterestsSelector = false
    @State private var showShareSheet = false
    @State private var itemToShare: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Interest selector bar
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(userSettings.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    showInterestsSelector = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            if viewModel.isPersonalizedLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = viewModel.personalizedErrorMessage {
                Spacer()
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Error loading personalized news")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        viewModel.fetchPersonalizedNews()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            } else if viewModel.personalizedArticles.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "newspaper")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No personalized news found")
                        .font(.headline)
                    
                    Text("Try selecting different interests or check back later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        showInterestsSelector = true
                    }) {
                        Text("Modify Interests")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.personalizedArticles) { article in
                        ArticleRowView(article: article, onShare: {
                            itemToShare = URL(string: article.url)
                            showShareSheet = true
                        })
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    viewModel.fetchPersonalizedNews()
                }
            }
        }
        .navigationTitle("For You")
        .sheet(isPresented: $showInterestsSelector) {
            InterestSelectorView(isPresented: $showInterestsSelector)
                .environmentObject(userSettings)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = itemToShare {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            // Initialize with settings
            let newViewModel = NewsViewModel(userSettings: userSettings)
            
            // Use reflection to set the StateObject
            if let mirror = Mirror(reflecting: _viewModel).children.first,
               let binding = mirror.value as? ReferenceWritableKeyPath<PersonalizedNewsView, NewsViewModel> {
                self[keyPath: binding] = newViewModel
            }
        }
    }
}
