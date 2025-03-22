import Foundation

// Analytics service to track user behavior and app usage
class AnalyticsService {
    // MARK: - Singleton
    static let shared = AnalyticsService()
    
    private init() {
        // Private initialization to ensure singleton usage
    }
    
    // MARK: - Screen Tracking
    func trackScreenView(screenName: String, screenClass: String) {
        // In a real app, this would integrate with Firebase Analytics, 
        // Amplitude, MixPanel, or another analytics provider
        print("📊 Screen View: \(screenName) - \(screenClass)")
    }
    
    // MARK: - Event Tracking
    func trackEvent(name: String, parameters: [String: Any]? = nil) {
        // In a real app, this would send the event to an analytics provider
        if let parameters = parameters {
            print("📊 Event: \(name) - Parameters: \(parameters)")
        } else {
            print("📊 Event: \(name)")
        }
    }
    
    // MARK: - User Properties
    func setUserProperty(value: Any?, forName name: String) {
        // In a real app, this would set user properties in the analytics system
        print("📊 User Property: \(name) - Value: \(value ?? "nil")")
    }
    
    // MARK: - Predefined Events
    
    // Tracking article interaction
    func trackArticleView(articleId: String, title: String, source: String, category: String?) {
        trackEvent(name: "article_view", parameters: [
            "article_id": articleId,
            "title": title,
            "source": source,
            "category": category ?? "none"
        ])
    }
    
    // Tracking article interactions
    func trackArticleBookmarked(articleId: String, title: String) {
        trackEvent(name: "article_bookmarked", parameters: [
            "article_id": articleId,
            "title": title
        ])
    }
    
    func trackArticleShared(articleId: String, title: String, platform: String? = nil) {
        var params: [String: Any] = [
            "article_id": articleId,
            "title": title
        ]
        
        if let platform = platform {
            params["platform"] = platform
        }
        
        trackEvent(name: "article_shared", parameters: params)
    }
    
    // Tracking search behavior
    func trackSearch(query: String, resultCount: Int) {
        trackEvent(name: "search_performed", parameters: [
            "query": query,
            "result_count": resultCount
        ])
    }
    
    // Tracking personalization
    func trackInterestSelected(interest: String) {
        trackEvent(name: "interest_selected", parameters: [
            "interest": interest
        ])
    }
    
    func trackInterestRemoved(interest: String) {
        trackEvent(name: "interest_removed", parameters: [
            "interest": interest
        ])
    }
    
    func trackCountryChanged(countryCode: String, countryName: String) {
        trackEvent(name: "country_changed", parameters: [
            "country_code": countryCode,
            "country_name": countryName
        ])
    }
    
    // Tracking app usage
    func trackAppOpen() {
        trackEvent(name: "app_open")
    }
    
    func trackAppBackground() {
        trackEvent(name: "app_background")
    }
    
    func trackSessionDuration(durationSeconds: Int) {
        trackEvent(name: "session_duration", parameters: [
            "duration_seconds": durationSeconds
        ])
    }
    
    func trackErrorOccurred(errorCode: String, errorMessage: String, screen: String) {
        trackEvent(name: "error_occurred", parameters: [
            "error_code": errorCode,
            "error_message": errorMessage,
            "screen": screen
        ])
    }
    
    // Tracking feature usage
    func trackFeatureUsed(featureName: String) {
        trackEvent(name: "feature_used", parameters: [
            "feature_name": featureName
        ])
    }
    
    func trackSettingChanged(settingName: String, value: Any) {
        trackEvent(name: "setting_changed", parameters: [
            "setting_name": settingName,
            "value": "\(value)"
        ])
    }
} 