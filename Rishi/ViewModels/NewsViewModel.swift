import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userCountry: String = "us"
    @Published var userCountryName: String = "United States"
    
    let newsService = NewsService()
    var cancellables = Set<AnyCancellable>()
    
    init(locationService: LocationService? = nil) {
        // Subscribe to location updates if provided
        locationService?.$currentCountry
            .sink { [weak self] country in
                self?.userCountry = country
                self?.fetchTopHeadlines()
            }
            .store(in: &cancellables)
        
        locationService?.$currentCountryName
            .sink { [weak self] name in
                self?.userCountryName = name
            }
            .store(in: &cancellables)
        
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
                print("Received \(response.results.count) articles")
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