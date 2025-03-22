import Foundation
import Combine

class ArticleSummaryService {
    // MARK: - Properties
    private let apiKey = "YOUR_AI_API_KEY" // Replace with actual key
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for article summaries
    private var summaryCache: [String: String] = [:]
    
    // MARK: - Public Methods
    
    /// Generate a summary for an article
    /// - Parameters:
    ///   - article: The article to summarize
    ///   - completion: Callback with the summary or error
    func generateSummary(for article: Article, completion: @escaping (Result<String, Error>) -> Void) {
        // Check cache first
        if let cachedSummary = summaryCache[article.url] {
            completion(.success(cachedSummary))
            return
        }
        
        // For demo purposes, simulate AI generation with a predefined summary
        // In a real app, this would make an API call to an AI service
        generateMockSummary(for: article) { [weak self] result in
            switch result {
            case .success(let summary):
                // Cache the result
                self?.summaryCache[article.url] = summary
                completion(.success(summary))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Clear the summary cache
    func clearCache() {
        summaryCache.removeAll()
    }
    
    // MARK: - Private Helper Methods
    
    /// Generate a mock summary for demo purposes
    /// In a real app, this would call an AI API
    private func generateMockSummary(for article: Article, completion: @escaping (Result<String, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Extract key information from the article
            let title = article.title
            let source = article.source.name
            let description = article.description ?? ""
            
            // Create a template-based summary
            let summary = """
            This article from \(source) discusses \(title.lowercased().replacingOccurrences(of: ".", with: "")).
            
            Key points:
            • \(self.generateKeyPoint(from: title))
            • \(self.generateKeyPoint(from: description))
            • The article provides context on the implications and potential outcomes.
            
            In conclusion, this is an important development worth following for its impact on \(self.generateRelevancePoint(from: title)).
            """
            
            completion(.success(summary))
        }
    }
    
    /// In a real app, this would make an API call to an AI service like OpenAI
    private func makeRealAPISummaryRequest(for article: Article, completion: @escaping (Result<String, Error>) -> Void) {
        // Construct the prompt
        let prompt = """
        Please summarize the following news article in 3-4 sentences. Include the main points only.
        
        Title: \(article.title)
        
        \(article.description ?? "")
        
        \(article.content ?? "")
        """
        
        // Create the request
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that summarizes news articles concisely."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.5
        ]
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make the API call
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { response in
                if let choice = response.choices.first, let content = choice.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "ArticleSummaryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No summary generated"])))
                }
            }
            .store(in: &cancellables)
    }
    
    // Helper to generate a key point from text
    private func generateKeyPoint(from text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        guard let sentence = sentences.first, !sentence.isEmpty else {
            return "The article provides detailed information on this topic"
        }
        
        // Capitalize first letter and ensure it ends with a period
        var result = sentence.prefix(1).uppercased() + sentence.dropFirst()
        if !result.hasSuffix(".") {
            result += "."
        }
        
        return result
    }
    
    // Helper to generate relevance from title
    private func generateRelevancePoint(from title: String) -> String {
        let keywords = ["economy", "politics", "technology", "health", "environment", "society", "global affairs", "local community"]
        let lowercasedTitle = title.lowercased()
        
        for keyword in keywords {
            if lowercasedTitle.contains(keyword) {
                return keyword
            }
        }
        
        return "current events"
    }
}

// Models for OpenAI API (only used in the real API implementation)
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String?
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
} 