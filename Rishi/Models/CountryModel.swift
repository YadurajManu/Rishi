import Foundation
import SwiftUI

struct Country: Identifiable, Hashable {
    let id: String // country code
    let name: String
    let flag: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        return lhs.id == rhs.id
    }
}

// Global list of supported countries
struct CountryList {
    static let countries: [Country] = [
        Country(id: "in", name: "India", flag: "🇮🇳"),
        Country(id: "us", name: "United States", flag: "🇺🇸"),
        Country(id: "gb", name: "United Kingdom", flag: "🇬🇧"),
        Country(id: "ca", name: "Canada", flag: "🇨🇦"),
        Country(id: "au", name: "Australia", flag: "🇦🇺"),
        Country(id: "sg", name: "Singapore", flag: "🇸🇬"),
        Country(id: "jp", name: "Japan", flag: "🇯🇵"),
        Country(id: "de", name: "Germany", flag: "🇩🇪"),
        Country(id: "fr", name: "France", flag: "🇫🇷"),
        Country(id: "it", name: "Italy", flag: "🇮🇹"),
        Country(id: "ru", name: "Russia", flag: "🇷🇺"),
        Country(id: "br", name: "Brazil", flag: "🇧🇷"),
        Country(id: "mx", name: "Mexico", flag: "🇲🇽"),
        Country(id: "za", name: "South Africa", flag: "🇿🇦"),
        Country(id: "cn", name: "China", flag: "🇨🇳"),
        Country(id: "ae", name: "UAE", flag: "🇦🇪"),
        Country(id: "pk", name: "Pakistan", flag: "🇵🇰"),
        Country(id: "ng", name: "Nigeria", flag: "🇳🇬")
    ]
    
    static func getCountry(byId id: String) -> Country {
        return countries.first { $0.id == id } ?? countries[0]
    }
} 