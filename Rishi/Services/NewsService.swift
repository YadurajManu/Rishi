import Foundation
import Combine

class NewsService {
    private let baseUrl = "https://newsdata.io/api/1/news"
    private var apiKey: String {
        // In a real app, store this securely
        return "pub_75826eef5f45466bc36645f999f1d07627ded"
    }
    
    func fetchNews(category: String? = nil, query: String? = nil) -> AnyPublisher<NewsResponse, Error> {
        var components = URLComponents(string: baseUrl)!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
        
        // Add optional parameters
        if let category = category {
            if category == "top" {
                // Top headlines don't need a category
            } else {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
        }
        
        if let query = query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        // Add country for better results
        queryItems.append(URLQueryItem(name: "country", value: "us"))
        
        // Add language parameter
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        
        components.queryItems = queryItems
        
        print("Request URL: \(components.url?.absoluteString ?? "invalid URL")")
        
        let request = URLRequest(url: components.url!)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { output -> Data in
                print("Response received: \(String(data: output.data, encoding: .utf8) ?? "Invalid data")")
                return output.data
            }
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
} 