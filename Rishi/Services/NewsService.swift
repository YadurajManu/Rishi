import Foundation
import Combine

class NewsService {
    private let baseUrl = "https://newsdata.io/api/1/news"
    private var apiKey: String {
        // In a real app, store this securely
        return "pub_75826eef5f45466bc36645f999f1d07627ded"
    }
    
    // Reference to the location service for country-based news
    let locationService = LocationService()
    
    func fetchNews(category: String? = nil, query: String? = nil, country: String? = nil) -> AnyPublisher<NewsResponse, Error> {
        var components = URLComponents(string: baseUrl)!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
        
        // Add optional parameters
        if let category = category, category != "top" {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let query = query {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        // Use provided country or fall back to location service
        let countryCode = country ?? locationService.currentCountry
        queryItems.append(URLQueryItem(name: "country", value: countryCode))
        
        // Add language parameter
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        
        components.queryItems = queryItems
        
        print("Request URL: \(components.url?.absoluteString ?? "invalid URL")")
        
        let request = URLRequest(url: components.url!)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                print("Network error: \(error.localizedDescription)")
                return error
            }
            .map { output -> Data in
                if let response = output.response as? HTTPURLResponse {
                    print("Response status code: \(response.statusCode)")
                }
                return output.data
            }
            .decode(type: NewsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
} 