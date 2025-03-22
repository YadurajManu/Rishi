import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userCountry: String = "in"
    @Published var userCountryName: String = "India"
    
    let newsService = NewsService()
    var cancellables = Set<AnyCancellable>()
    private var userSettings: UserSettings?
    
    init(userSettings: UserSettings? = nil) {
        self.userSettings = userSettings
        
        // Subscribe to country changes
        userSettings?.$selectedCountry
            .sink { [weak self] country in
                self?.userCountry = country.id
                self?.userCountryName = country.name
                self?.fetchTopHeadlines()
            }
            .store(in: &cancellables)
        
        // Set default country from settings
        if let settings = userSettings {
            userCountry = settings.selectedCountry.id
            userCountryName = settings.selectedCountry.name
        }
        
        fetchTopHeadlines()
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
                print("Received \(response.results.count) articles for country: \(self?.userCountry ?? "unknown")")
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
            }
            .store(in: &cancellables)
    }
} 