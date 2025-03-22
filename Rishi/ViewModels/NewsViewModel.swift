import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    let newsService = NewsService()
    var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchTopHeadlines()
    }
    
    func fetchTopHeadlines() {
        isLoading = true
        errorMessage = nil
        
        newsService.fetchNews(category: "top")
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.articles
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
        
        newsService.fetchNews(query: query)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.articles
            }
            .store(in: &cancellables)
    }
    
    func fetchNewsByCategory(category: String) {
        isLoading = true
        errorMessage = nil
        
        newsService.fetchNews(category: category)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.articles = response.articles
            }
            .store(in: &cancellables)
    }
} 