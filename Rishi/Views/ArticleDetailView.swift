import SwiftUI
import SafariServices
import UIKit

struct ArticleDetailView: View {
    let article: Article
    @State private var showSafari = false
    @State private var showShareSheet = false
    @State private var isBookmarked = false
    @State private var readingProgress: CGFloat = 0.0
    @State private var bookmarkScale: CGFloat = 1.0
    @State private var showRelatedArticles = false
    @State private var showFullText = true // Simulated for the prototype
    @State private var showWebView = false
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var progressPercentage: Double = 0
    @State private var showProgress = false
    @ObservedObject var newsService = NewsService()
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with image
                    headerView
                    
                    // Article content
                    contentView
                    
                    // Reading progress
                    if showProgress {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reading Progress")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            HStack {
                                ProgressView(value: progressPercentage, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(height: 8)
                                
                                Text("\(Int(progressPercentage * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Divider before related articles
                    Divider()
                        .padding(.vertical)
                    
                    // Related articles section
                    relatedArticlesView
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scrollView")).minY
                        )
                    }
                )
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            scrollViewHeight = geometry.size.height
                        }
                    }
                )
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                // Calculate scroll percentage
                let contentHeight = scrollViewHeight
                if contentHeight > 0 {
                    let offsetPercentage = max(0, min(1, Double(-offset) / Double(contentHeight)))
                    progressPercentage = offsetPercentage
                    
                    // Save progress to UserSettings
                    userSettings.updateArticleProgress(for: article.url, progress: progressPercentage)
                }
            }
            .onAppear {
                // Mark article as read
                userSettings.markArticleAsRead(article)
                
                // Check if article is bookmarked
                isBookmarked = userSettings.isArticleBookmarked(article)
                
                // Load related articles
                newsService.fetchRelatedArticles(to: article)
                
                // Load saved progress if any
                progressPercentage = userSettings.getArticleProgress(for: article.url)
                if progressPercentage > 0.1 {
                    showProgress = true
                }
                
                // After a short delay, show the progress indicator if the user hasn't seen this article before
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showProgress = true
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        toggleBookmark()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .yellow : .blue)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isBookmarked)
                    
                    Button(action: {
                        showWebView = true
                    }) {
                        Image(systemName: "safari")
                    }
                }
            )
            .sheet(isPresented: $showWebView) {
                SafariWebView(url: URL(string: article.url)!)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [URL(string: article.url)!])
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .clipped()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.system(size: userSettings.fontSize.headlineSize))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(article.source.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let publishedAt = ISO8601DateFormatter().date(from: article.publishedAt) {
                        Text(formatDate(publishedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("\(article.readingTime) min read", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { toggleBookmark() }) {
                        Label(isBookmarked ? "Bookmarked" : "Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.caption)
                            .foregroundColor(isBookmarked ? .yellow : .blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let description = article.description {
                Text(description)
                    .font(.system(size: userSettings.fontSize.textSize + 2))
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            
            // AI Summary section
            ArticleSummaryView(article: article)
                .padding(.horizontal)
            
            if let content = article.content {
                // Clean up content if needed (remove truncation markers)
                let cleanContent = content.replacingOccurrences(of: "… \\[\\+\\d+ chars\\]", with: "...", options: .regularExpression)
                
                Text(cleanContent)
                    .font(.system(size: userSettings.fontSize.textSize))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            
            if let author = article.author, !author.isEmpty {
                Text("By \(author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            Button(action: {
                showWebView = true
            }) {
                Text("Read full article")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(userSettings.appTheme.accentColor)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var relatedArticlesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .padding(.horizontal)
            
            if newsService.relatedArticles.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(newsService.relatedArticles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                RelatedArticleCard(article: article)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func toggleBookmark() {
        if isBookmarked {
            userSettings.removeBookmark(article)
        } else {
            userSettings.addBookmark(article)
        }
        isBookmarked.toggle()
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct RelatedArticleCard: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(8)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(article.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Text(article.source.name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 200)
    }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Nothing to do
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 