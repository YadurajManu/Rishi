import Foundation

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