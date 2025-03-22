import Foundation

// News API Response Models
struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
} 