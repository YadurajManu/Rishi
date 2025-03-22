import Foundation
import Combine

class NewsService {
    private let baseUrl = "https://newsdata.io/api/1/news"
    private var apiKey: String {
        // In a real app, store this securely
        return "YOUR_NEWSDATA_IO_API_KEY" // Replace with your actual API key
    }
    
    func fetchNews(category: String? = nil, query: String? = nil) -> AnyPublisher<NewsResponse, Error> {
        var components = URLComponents(string: baseUrl)!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
        
        // Add optional parameters
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let query = query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
} 