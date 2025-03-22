import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var trendingArticles: [Article] = []
    @Published var personalizedArticles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isPersonalizedLoading: Bool = false
    @Published var personalizedErrorMessage: String? = nil
    @Published var userCountry: String = "in"
    @Published var userCountryName: String = "India"
    @Published var lastRefreshTime: Date? = nil
    
    let newsService = NewsService()
    var cancellables = Set<AnyCancellable>()
    private var userSettings: UserSettings?
    private var refreshTimer: Timer?
    
    init(userSettings: UserSettings? = nil) {
        self.userSettings = userSettings
        
        // Subscribe to country changes
        userSettings?.$selectedCountry
            .sink { [weak self] country in
                self?.userCountry = country.id
                self?.userCountryName = country.name
                self?.fetchTopHeadlines()
                self?.fetchTrendingNews()
                self?.fetchPersonalizedNews()
            }
            .store(in: &cancellables)
        
        // Subscribe to interests changes
        userSettings?.$interests
            .sink { [weak self] _ in
                self?.fetchPersonalizedNews()
            }
            .store(in: &cancellables)
            
        // Subscribe to auto-refresh interval changes
        userSettings?.$autoRefreshInterval
            .sink { [weak self] interval in
                self?.setupAutoRefresh(minutes: interval)
            }
            .store(in: &cancellables)
        
        // Set default country from settings
        if let settings = userSettings {
            userCountry = settings.selectedCountry.id
            userCountryName = settings.selectedCountry.name
            setupAutoRefresh(minutes: settings.autoRefreshInterval)
        }
        
        fetchTopHeadlines()
        fetchTrendingNews()
        fetchPersonalizedNews()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func fetchTopHeadlines() {
        isLoading = true
        errorMessage = nil
        
        newsService.fetchNews(category: "top", country: userCountry)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("Error fetching headlines: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.results
                self?.lastRefreshTime = Date()
                print("Received \(response.results.count) articles for country: \(self?.userCountry ?? "unknown")")
            }
            .store(in: &cancellables)
    }
    
    func fetchTrendingNews() {
        // Here we'll use a different category to simulate trending news
        // In a real app, this could be based on engagement metrics or a dedicated endpoint
        newsService.fetchNews(category: "technology", country: userCountry)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Error fetching trending news: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                if !response.results.isEmpty {
                    self?.trendingArticles = Array(response.results.prefix(10))
                    print("Received \(response.results.count) trending articles")
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchPersonalizedNews() {
        guard let userSettings = userSettings, !userSettings.interests.isEmpty else {
            // No interests defined
            personalizedArticles = []
            return
        }
        
        isPersonalizedLoading = true
        personalizedErrorMessage = nil
        
        // Join interests with OR for the query
        let interestsQuery = userSettings.interests.joined(separator: " OR ")
        
        newsService.fetchNews(query: interestsQuery, country: userCountry)
            .sink { [weak self] completion in
                self?.isPersonalizedLoading = false
                if case .failure(let error) = completion {
                    self?.personalizedErrorMessage = error.localizedDescription
                    print("Error fetching personalized news: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                self?.personalizedArticles = response.results
                print("Received \(response.results.count) personalized articles")
            }
            .store(in: &cancellables)
    }
    
    func searchNews(query: String) {
        guard !query.isEmpty else {
            fetchTopHeadlines()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        newsService.fetchNews(query: query, country: userCountry)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.results
                self?.lastRefreshTime = Date()
            }
            .store(in: &cancellables)
    }
    
    func fetchNewsByCategory(category: String) {
        isLoading = true
        errorMessage = nil
        
        newsService.fetchNews(category: category, country: userCountry)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.results
                self?.lastRefreshTime = Date()
            }
            .store(in: &cancellables)
    }
    
    func refreshAllContent() {
        fetchTopHeadlines()
        fetchTrendingNews()
        fetchPersonalizedNews()
    }
    
    private func setupAutoRefresh(minutes: Int) {
        // Remove existing timer if any
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Only set up a timer if interval is greater than 0
        guard minutes > 0 else { return }
        
        // Convert minutes to seconds
        let seconds = TimeInterval(minutes * 60)
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            self?.refreshAllContent()
        }
    }
    
    func getFormattedRefreshTime() -> String {
        guard let lastRefresh = lastRefreshTime else {
            return "Never refreshed"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        return "Last updated \(formatter.localizedString(for: lastRefresh, relativeTo: Date()))"
    }
} 