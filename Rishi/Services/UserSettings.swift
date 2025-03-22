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
    
    // Default categories
    private let defaultCategories = [
        "business", "entertainment", "environment", "food",
        "health", "politics", "science", "sports", "technology", "top", "world"
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
    }
    
    // Get all available categories
    func getAllCategories() -> [String] {
        return defaultCategories
    }
    
    // Get visible categories
    func getVisibleCategories() -> [String] {
        return showCategories.filter { $0.value }.map { $0.key }
    }
} 