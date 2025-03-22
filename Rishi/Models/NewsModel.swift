import Foundation

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int?
    let results: [Article]
}

struct Article: Codable, Identifiable {
    var id: String { url }
    let title: String
    let link: String
    let keywords: [String]?
    let creator: [String]?
    let video_url: String?
    let description: String?
    let content: String?
    let pubDate: String
    let image_url: String?
    let source_id: String
    let category: [String]?
    let country: [String]?
    let language: String
    
    // Computed properties to match our UI expectations
    var url: String { link }
    var author: String? { creator?.first }
    var urlToImage: String? { image_url }
    var publishedAt: String { pubDate }
    var source: Source {
        Source(id: source_id, name: source_id)
    }
}

struct Source: Codable {
    let id: String?
    let name: String
} 