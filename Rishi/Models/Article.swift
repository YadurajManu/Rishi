import Foundation

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