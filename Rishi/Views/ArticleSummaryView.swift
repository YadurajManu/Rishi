import SwiftUI

struct ArticleSummaryView: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var summary: String?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showFullSummary = false
    
    private let summaryService = ArticleSummaryService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(userSettings.appTheme.accentColor)
                
                Spacer()
                
                if !isLoading && summary != nil {
                    Button(action: {
                        withAnimation {
                            showFullSummary.toggle()
                        }
                    }) {
                        Image(systemName: showFullSummary ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Generating summary...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if let error = error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text("Couldn't generate summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        generateSummary()
                    }) {
                        Text("Try Again")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(userSettings.appTheme.accentColor)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            } else if let summary = summary {
                VStack(alignment: .leading, spacing: 12) {
                    Text(showFullSummary ? summary : summary.components(separatedBy: "\n\n").first ?? summary)
                        .font(.system(size: userSettings.fontSize.textSize))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !showFullSummary && summary.contains("\n\n") {
                        Button(action: {
                            withAnimation {
                                showFullSummary = true
                            }
                        }) {
                            Text("Show more")
                                .font(.caption)
                                .foregroundColor(userSettings.appTheme.accentColor)
                        }
                    }
                }
            } else {
                Button(action: {
                    generateSummary()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate AI Summary")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(userSettings.appTheme.accentColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "autoGenerateSummaries") {
                generateSummary()
            }
        }
    }
    
    private func generateSummary() {
        isLoading = true
        error = nil
        
        summaryService.generateSummary(for: article) { result in
            isLoading = false
            
            switch result {
            case .success(let summary):
                self.summary = summary
            case .failure(let error):
                self.error = error
            }
        }
        
        // Track analytics
        AnalyticsService.shared.trackFeatureUsed(featureName: "article_summary")
    }
} 