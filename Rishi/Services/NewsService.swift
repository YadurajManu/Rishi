import Foundation
import Combine

class NewsService: ObservableObject {
    // Primary API endpoints
    private let newsApiBaseUrl = "https://newsapi.org/v2"
    private let newsApiKey = "5e7bad98b99548c59ef093ed5ef77c70" // Updated API key
    
    // Additional news sources
    private let guardianBaseUrl = "https://content.guardianapis.com"
    private let guardianApiKey = "2772af90-c352-4a8d-ad2e-90e2f1061fa3" // Updated Guardian API key
    
    @Published var topHeadlines: [Article] = []
    @Published var categoryNews: [String: [Article]] = [:]
    @Published var searchResults: [Article] = []
    @Published var personalizedNews: [Article] = []
    @Published var trendingTopics: [String] = []
    @Published var relatedArticles: [Article] = []
    
    @Published var isLoadingTopHeadlines = false
    @Published var isLoadingCategoryNews = false
    @Published var isLoadingSearchResults = false
    @Published var isLoadingPersonalizedNews = false
    
    @Published var topHeadlinesError: Error? = nil
    @Published var categoryNewsError: Error? = nil
    @Published var searchResultsError: Error? = nil
    @Published var personalizedNewsError: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cache settings
    private let cacheExpirationTime: TimeInterval = 15 * 60 // 15 minutes
    private var lastFetchTime: [String: Date] = [:]
    
    // Fetch top headlines
    func fetchTopHeadlines(country: String = "in", pageSize: Int = 20, page: Int = 1) {
        let cacheKey = "topHeadlines-\(country)-\(pageSize)-\(page)"
        
        // Check cache
        if let cachedTime = lastFetchTime[cacheKey], 
           Date().timeIntervalSince(cachedTime) < cacheExpirationTime,
           !topHeadlines.isEmpty {
            return
        }
        
        isLoadingTopHeadlines = true
        topHeadlinesError = nil
        
        var components = URLComponents(string: "\(newsApiBaseUrl)/top-headlines")
        components?.queryItems = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "apiKey", value: newsApiKey)
        ]
        
        guard let url = components?.url else {
            isLoadingTopHeadlines = false
            topHeadlinesError = NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingTopHeadlines = false
                if case .failure(let error) = completion {
                    self?.topHeadlinesError = error
                }
            } receiveValue: { [weak self] response in
                self?.topHeadlines = response.articles
                self?.lastFetchTime[cacheKey] = Date()
                // Generate trending topics from headlines
                self?.generateTrendingTopics(from: response.articles)
            }
            .store(in: &cancellables)
    }
    
    // Fetch category news
    func fetchCategoryNews(category: String, country: String = "in", pageSize: Int = 20) {
        let cacheKey = "category-\(category)-\(country)-\(pageSize)"
        
        // Check cache
        if let cachedTime = lastFetchTime[cacheKey], 
           Date().timeIntervalSince(cachedTime) < cacheExpirationTime,
           categoryNews[category]?.isEmpty == false {
            return
        }
        
        isLoadingCategoryNews = true
        categoryNewsError = nil
        
        var components = URLComponents(string: "\(newsApiBaseUrl)/top-headlines")
        components?.queryItems = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "apiKey", value: newsApiKey)
        ]
        
        guard let url = components?.url else {
            isLoadingCategoryNews = false
            categoryNewsError = NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingCategoryNews = false
                if case .failure(let error) = completion {
                    self?.categoryNewsError = error
                }
            } receiveValue: { [weak self] response in
                self?.categoryNews[category] = response.articles
                self?.lastFetchTime[cacheKey] = Date()
            }
            .store(in: &cancellables)
    }
    
    // Search news
    func searchNews(query: String, sortBy: String = "relevancy", pageSize: Int = 30, page: Int = 1) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let cacheKey = "search-\(query)-\(sortBy)-\(pageSize)-\(page)"
        
        // Searches are always fresh for now
        isLoadingSearchResults = true
        searchResultsError = nil
        
        var components = URLComponents(string: "\(newsApiBaseUrl)/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "apiKey", value: newsApiKey)
        ]
        
        guard let url = components?.url else {
            isLoadingSearchResults = false
            searchResultsError = NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingSearchResults = false
                if case .failure(let error) = completion {
                    self?.searchResultsError = error
                }
            } receiveValue: { [weak self] response in
                self?.searchResults = response.articles
                self?.lastFetchTime[cacheKey] = Date()
            }
            .store(in: &cancellables)
    }
    
    // Fetch personalized news based on user interests
    func fetchPersonalizedNews(interests: [String], pageSize: Int = 30) {
        guard !interests.isEmpty else {
            personalizedNews = []
            return
        }
        
        let interestsKey = interests.sorted().joined(separator: ",")
        let cacheKey = "personalized-\(interestsKey)"
        
        // Check cache (shorter time for personalized content)
        if let cachedTime = lastFetchTime[cacheKey], 
           Date().timeIntervalSince(cachedTime) < cacheExpirationTime / 2,
           !personalizedNews.isEmpty {
            return
        }
        
        isLoadingPersonalizedNews = true
        personalizedNewsError = nil
        
        // Create a query from interests (up to 5 to avoid too long URLs)
        let queryInterests = Array(interests.prefix(5)).joined(separator: " OR ")
        
        var components = URLComponents(string: "\(newsApiBaseUrl)/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: queryInterests),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "apiKey", value: newsApiKey)
        ]
        
        guard let url = components?.url else {
            isLoadingPersonalizedNews = false
            personalizedNewsError = NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingPersonalizedNews = false
                if case .failure(let error) = completion {
                    self?.personalizedNewsError = error
                }
            } receiveValue: { [weak self] response in
                self?.personalizedNews = response.articles
                self?.lastFetchTime[cacheKey] = Date()
            }
            .store(in: &cancellables)
    }
    
    // New method: Fetch related articles based on current article
    func fetchRelatedArticles(to article: Article) {
        // Extract keywords from article title and description
        var keywords = extractKeywords(from: article.title)
        if let description = article.description {
            keywords.append(contentsOf: extractKeywords(from: description))
        }
        
        // Remove duplicates and limit to top 5 most relevant keywords
        keywords = Array(Set(keywords)).prefix(5).map { $0 }
        
        // Create query string
        let query = keywords.joined(separator: " OR ")
        
        var components = URLComponents(string: "\(newsApiBaseUrl)/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sortBy", value: "relevancy"),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "apiKey", value: newsApiKey)
        ]
        
        guard let url = components?.url else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // Handle completion
            } receiveValue: { [weak self] response in
                // Filter out the original article and limit to 5 related articles
                self?.relatedArticles = response.articles
                    .filter { $0.url != article.url }
                    .prefix(5)
                    .map { $0 }
            }
            .store(in: &cancellables)
    }
    
    // New method: Fetch Guardian articles
    func fetchGuardianArticles(section: String = "world", pageSize: Int = 20) {
        var components = URLComponents(string: "\(guardianBaseUrl)/search")
        components?.queryItems = [
            URLQueryItem(name: "section", value: section),
            URLQueryItem(name: "page-size", value: "\(pageSize)"),
            URLQueryItem(name: "api-key", value: guardianApiKey),
            URLQueryItem(name: "show-fields", value: "headline,byline,thumbnail,body,publication")
        ]
        
        guard let url = components?.url else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GuardianResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Guardian API Error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                // Process Guardian articles and convert to the standard Article format
                let articles = response.response.results.compactMap { guardianArticle -> Article? in
                    return self?.convertGuardianToArticle(guardianArticle)
                }
                
                // Here we could add the articles to a new published property or a category
                // For example, add to category news if needed
                self?.categoryNews["guardian"] = articles
            }
            .store(in: &cancellables)
    }
    
    // Helper method to convert Guardian article to our standard Article model
    private func convertGuardianToArticle(_ guardianArticle: GuardianArticle) -> Article {
        // The Guardian API uses a different date format, so we need to convert it
        // Format: 2023-03-22T12:00:00Z
        let publishedDate = guardianArticle.webPublicationDate
        
        return Article(
            source: Source(id: "guardian", name: "The Guardian"),
            author: guardianArticle.fields?.byline,
            title: guardianArticle.webTitle,
            description: guardianArticle.fields?.headline,
            url: guardianArticle.webUrl,
            urlToImage: guardianArticle.fields?.thumbnail,
            publishedAt: publishedDate, // Guardian already uses ISO8601 format
            content: guardianArticle.fields?.body?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil) // Strip HTML tags
        )
    }
    
    // Generate trending topics from headlines
    private func generateTrendingTopics(from articles: [Article]) {
        // Extract all words from titles
        let allWords = articles.flatMap { extractKeywords(from: $0.title) }
        
        // Count word frequency
        var wordCounts: [String: Int] = [:]
        allWords.forEach { word in
            wordCounts[word, default: 0] += 1
        }
        
        // Filter out common stop words and low-frequency words
        let filteredWords = wordCounts.filter { word, count in
            !isStopWord(word) && count > 1 && word.count > 3
        }
        
        // Sort by frequency and take top 10
        let sortedTopics = filteredWords.sorted { $0.value > $1.value }.prefix(10).map { $0.key }
        
        // Update trending topics
        trendingTopics = sortedTopics
    }
    
    // Extract keywords from text
    private func extractKeywords(from text: String) -> [String] {
        // Simple implementation - split by spaces and clean up
        return text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 3 }
    }
    
    // Check if word is a stop word (common words to ignore)
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = ["the", "and", "that", "have", "for", "not", "with", "you", "this", "but"]
        return stopWords.contains(word.lowercased())
    }
    
    // Clear cache
    func clearCache() {
        lastFetchTime.removeAll()
    }
}

// Data models
struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}

struct Article: Codable, Identifiable, Equatable {
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
    
    var id: String { url }
    
    // Compute estimated reading time
    var readingTime: Int {
        let wordCount = (content ?? "").split(separator: " ").count + 
                       title.split(separator: " ").count +
                       (description ?? "").split(separator: " ").count
        
        // Average reading speed: 200 words per minute
        return max(1, Int(ceil(Double(wordCount) / 200.0)))
    }
    
    // Check if articles are equal (by URL)
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.url == rhs.url
    }
}

struct Source: Codable, Equatable {
    let id: String?
    let name: String
}

// Guardian API Response Models
struct GuardianResponse: Codable {
    let response: GuardianResponseContent
}

struct GuardianResponseContent: Codable {
    let status: String
    let total: Int
    let results: [GuardianArticle]
}

struct GuardianArticle: Codable, Identifiable {
    let id: String
    let sectionId: String
    let webPublicationDate: String
    let webTitle: String
    let webUrl: String
    let fields: GuardianFields?
}

struct GuardianFields: Codable {
    let headline: String?
    let byline: String?
    let thumbnail: String?
    let body: String?
} 