import Foundation
import Combine
import SwiftUI

class UserSettings: ObservableObject {
    // Keys for UserDefaults
    private enum Keys {
        static let countryCode = "userCountryCode"
        static let darkMode = "darkMode"
        static let notificationsEnabled = "notificationsEnabled"
        static let fontSize = "fontSize"
        static let showCategories = "showCategories"
        static let bookmarkedArticles = "bookmarkedArticles"
        static let interests = "interests"
        static let autoRefreshInterval = "autoRefreshInterval"
        static let readArticles = "readArticles"
        static let readingHistory = "readingHistory"
        static let appTheme = "appTheme"
    }
    
    // Current selected country
    @Published var selectedCountry: Country {
        didSet {
            UserDefaults.standard.set(selectedCountry.id, forKey: Keys.countryCode)
        }
    }
    
    // Other settings
    @Published var darkMode: Bool {
        didSet {
            UserDefaults.standard.set(darkMode, forKey: Keys.darkMode)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }
    
    @Published var fontSize: FontSize {
        didSet {
            UserDefaults.standard.set(fontSize.rawValue, forKey: Keys.fontSize)
        }
    }
    
    @Published var showCategories: [String: Bool] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(showCategories) {
                UserDefaults.standard.set(data, forKey: Keys.showCategories)
            }
        }
    }
    
    // Bookmarked articles
    @Published var bookmarkedArticles: [Article] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(bookmarkedArticles) {
                UserDefaults.standard.set(data, forKey: Keys.bookmarkedArticles)
            }
        }
    }
    
    // User interests for content personalization
    @Published var interests: [String] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(interests) {
                UserDefaults.standard.set(data, forKey: Keys.interests)
            }
        }
    }
    
    // Auto-refresh interval in minutes (0 = disabled)
    @Published var autoRefreshInterval: Int {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: Keys.autoRefreshInterval)
        }
    }
    
    // Reading history - articles the user has read
    @Published var readingHistory: [ReadHistoryItem] = [] {
        didSet {
            // Keep only the last 100 articles
            if readingHistory.count > 100 {
                readingHistory = Array(readingHistory.prefix(100))
            }
            
            if let data = try? JSONEncoder().encode(readingHistory) {
                UserDefaults.standard.set(data, forKey: Keys.readingHistory)
            }
        }
    }
    
    // Set of read article URLs for quick lookup
    @Published var readArticles: Set<String> = [] {
        didSet {
            if let data = try? JSONEncoder().encode(Array(readArticles)) {
                UserDefaults.standard.set(data, forKey: Keys.readArticles)
            }
        }
    }
    
    // App theme
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: Keys.appTheme)
        }
    }
    
    // Font size options
    enum FontSize: Int, CaseIterable {
        case small = 0
        case medium = 1
        case large = 2
        
        var title: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            }
        }
        
        var textSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
        
        var headlineSize: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 20
            case .large: return 24
            }
        }
    }
    
    // App theme options
    enum AppTheme: Int, CaseIterable {
        case system = 0
        case light = 1
        case dark = 2
        case blue = 3
        case green = 4
        case orange = 5
        
        var title: String {
            switch self {
            case .system: return "System Default"
            case .light: return "Light"
            case .dark: return "Dark"
            case .blue: return "Blue"
            case .green: return "Green"
            case .orange: return "Orange"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .system, .light, .dark: return .blue
            case .blue: return Color(red: 0, green: 0.5, blue: 0.9)
            case .green: return Color(red: 0.1, green: 0.7, blue: 0.4)
            case .orange: return Color(red: 1.0, green: 0.5, blue: 0.1)
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .system, .light: return Color(.systemBackground)
            case .dark: return Color.black
            case .blue: return Color(red: 0.9, green: 0.95, blue: 1.0)
            case .green: return Color(red: 0.9, green: 1.0, blue: 0.95)
            case .orange: return Color(red: 1.0, green: 0.98, blue: 0.95)
            }
        }
        
        var textColor: Color {
            switch self {
            case .system, .light, .blue, .green, .orange: return Color.primary
            case .dark: return Color.white
            }
        }
    }
    
    // Reading history item
    struct ReadHistoryItem: Codable, Identifiable {
        let id: UUID
        let article: Article
        let timestamp: Date
        
        init(article: Article, timestamp: Date = Date()) {
            self.id = UUID()
            self.article = article
            self.timestamp = timestamp
        }
    }
    
    // Default categories
    private let defaultCategories = [
        "business", "entertainment", "environment", "food",
        "health", "politics", "science", "sports", "technology", "top", "world"
    ]
    
    // Interest suggestions by category
    private let interestSuggestions: [String: [String]] = [
        "business": ["finance", "stocks", "economy", "startups", "investment", "markets"],
        "technology": ["AI", "software", "gadgets", "web development", "mobile", "programming"],
        "health": ["fitness", "nutrition", "medicine", "wellness", "mental health", "covid"],
        "sports": ["cricket", "football", "tennis", "olympics", "basketball", "hockey"],
        "entertainment": ["movies", "music", "celebrities", "television", "streaming", "bollywood"],
        "science": ["space", "research", "environment", "climate", "discoveries", "biology"]
    ]
    
    init() {
        // Load country or use default (India)
        let savedCountryCode = UserDefaults.standard.string(forKey: Keys.countryCode) ?? "in"
        self.selectedCountry = CountryList.getCountry(byId: savedCountryCode)
        
        // Load other settings or use defaults
        self.darkMode = UserDefaults.standard.bool(forKey: Keys.darkMode)
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        
        // Font size
        let rawFontSize = UserDefaults.standard.integer(forKey: Keys.fontSize)
        self.fontSize = FontSize(rawValue: rawFontSize) ?? .medium
        
        // App theme
        let rawTheme = UserDefaults.standard.integer(forKey: Keys.appTheme)
        self.appTheme = AppTheme(rawValue: rawTheme) ?? .system
        
        // Categories visibility
        if let data = UserDefaults.standard.data(forKey: Keys.showCategories),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            self.showCategories = decoded
        } else {
            // Initialize with all categories visible
            var initialCategories = [String: Bool]()
            defaultCategories.forEach { initialCategories[$0] = true }
            self.showCategories = initialCategories
        }
        
        // Load bookmarked articles
        if let data = UserDefaults.standard.data(forKey: Keys.bookmarkedArticles),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            self.bookmarkedArticles = decoded
        } else {
            self.bookmarkedArticles = []
        }
        
        // Load user interests
        if let data = UserDefaults.standard.data(forKey: Keys.interests),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.interests = decoded
        } else {
            self.interests = []
        }
        
        // Load auto-refresh interval
        self.autoRefreshInterval = UserDefaults.standard.integer(forKey: Keys.autoRefreshInterval)
        
        // Load reading history
        if let data = UserDefaults.standard.data(forKey: Keys.readingHistory),
           let decoded = try? JSONDecoder().decode([ReadHistoryItem].self, from: data) {
            self.readingHistory = decoded
        } else {
            self.readingHistory = []
        }
        
        // Load read articles
        if let data = UserDefaults.standard.data(forKey: Keys.readArticles),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.readArticles = Set(decoded)
        } else {
            self.readArticles = []
        }
    }
    
    // MARK: - Helper Methods
    
    func getAllCategories() -> [String] {
        return defaultCategories
    }
    
    func getSuggestedInterests() -> [String] {
        var suggestions = Set<String>()
        for category in interestSuggestions.keys {
            if let topicSuggestions = interestSuggestions[category] {
                suggestions.formUnion(topicSuggestions)
            }
        }
        return Array(suggestions).sorted()
    }
    
    func getSuggestedInterests(forCategory category: String?) -> [String] {
        guard let category = category, 
              let suggestions = interestSuggestions[category.lowercased()] else {
            return getSuggestedInterests()
        }
        return suggestions.sorted()
    }
    
    func addBookmark(_ article: Article) {
        if !isArticleBookmarked(article) {
            bookmarkedArticles.append(article)
        }
    }
    
    func removeBookmark(_ article: Article) {
        bookmarkedArticles.removeAll { $0.url == article.url }
    }
    
    func isArticleBookmarked(_ article: Article) -> Bool {
        return bookmarkedArticles.contains { $0.url == article.url }
    }
    
    func markArticleAsRead(_ article: Article) {
        readArticles.insert(article.url)
        
        // Add to reading history
        let historyItem = ReadHistoryItem(article: article)
        readingHistory.insert(historyItem, at: 0)
    }
    
    func isArticleRead(_ article: Article) -> Bool {
        return readArticles.contains(article.url)
    }
    
    func clearReadingHistory() {
        readingHistory.removeAll()
        readArticles.removeAll()
    }
    
    // MARK: - Interest Management
    
    func toggleInterest(_ interest: String) {
        if isInterestSelected(interest) {
            interests.removeAll { $0 == interest }
        } else {
            interests.append(interest)
        }
    }
    
    func isInterestSelected(_ interest: String) -> Bool {
        return interests.contains(interest)
    }
    
    func clearAllInterests() {
        interests.removeAll()
    }
} 