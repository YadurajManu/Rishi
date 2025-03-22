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
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Featured Image
                    if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(height: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(height: 250)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .frame(height: 250)
                            }
                        }
                        .overlay(
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        toggleBookmark()
                                    }) {
                                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                            .font(.title2)
                                            .foregroundColor(isBookmarked ? .yellow : .white)
                                            .padding(10)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                            .scaleEffect(bookmarkScale)
                                            .shadow(radius: 2)
                                    }
                                    .padding(.trailing, 16)
                                    .padding(.top, 16)
                                }
                                
                                Spacer()
                                
                                // Source overlay on image
                                HStack {
                                    Text(article.source.name)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(5)
                                        .padding(.leading, 16)
                                        .padding(.bottom, 16)
                                    
                                    Spacer()
                                }
                            }
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with date and reading time
                        HStack {
                            Text(formattedDate(from: article.publishedAt))
                                .font(.system(size: userSettings.fontSize.textSize - 2))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(estimateReadingTime()) min read")
                                .font(.system(size: userSettings.fontSize.textSize - 2))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Title
                        Text(article.title)
                            .font(.system(size: userSettings.fontSize.headlineSize + 4))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Author
                        if let author = article.author, !author.isEmpty {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Text(author)
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Description
                        if let description = article.description, !description.isEmpty {
                            Text(description)
                                .font(.system(size: userSettings.fontSize.textSize + 2))
                                .fontWeight(.medium)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // Full content (simulated for prototype)
                        if showFullText {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("This is a simulated full text of the article. In a real app, this would be the complete article content fetched from the API or the source website. The content would include paragraphs, quotes, embedded media, and more.")
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .padding(.horizontal)
                                
                                Text("The content would continue here with more information about the article topic. This could include background information, expert opinions, or related developments.")
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .padding(.horizontal)
                                
                                Text("Additional paragraphs would provide more depth on the topic, potentially including statistics, historical context, or future implications.")
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .padding(.horizontal)
                                
                                // Read more button
                                Button(action: {
                                    showSafari = true
                                }) {
                                    Text("Read the full article on \(article.source.name)")
                                        .font(.system(size: userSettings.fontSize.textSize))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(userSettings.appTheme.accentColor)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.top, 16)
                        } else {
                            // Read more button
                            Button(action: {
                                showSafari = true
                            }) {
                                Text("Read the full article on \(article.source.name)")
                                    .font(.system(size: userSettings.fontSize.textSize))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(userSettings.appTheme.accentColor)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 16)
                        }
                        
                        // Action buttons
                        HStack(spacing: 16) {
                            Spacer()
                            
                            Button(action: {
                                showShareSheet = true
                            }) {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title3)
                                    Text("Share")
                                        .font(.caption)
                                }
                                .foregroundColor(userSettings.appTheme.accentColor)
                            }
                            
                            Button(action: {
                                toggleBookmark()
                            }) {
                                VStack {
                                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                        .font(.title3)
                                    Text(isBookmarked ? "Saved" : "Save")
                                        .font(.caption)
                                }
                                .foregroundColor(isBookmarked ? .yellow : userSettings.appTheme.accentColor)
                            }
                            
                            Button(action: {
                                showRelatedArticles.toggle()
                            }) {
                                VStack {
                                    Image(systemName: "rectangle.stack")
                                        .font(.title3)
                                    Text("Related")
                                        .font(.caption)
                                }
                                .foregroundColor(userSettings.appTheme.accentColor)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        
                        // Related articles section
                        if showRelatedArticles {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Related Articles")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(0..<3) { i in
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "newspaper")
                                                    .foregroundColor(.gray)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Related article #\(i+1) title would appear here")
                                                .font(.subheadline)
                                                .lineLimit(2)
                                            
                                            Text("Source name • Timeframe")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
                .onAppear {
                    // Mark article as read
                    userSettings.markArticleAsRead(article)
                    
                    // Check bookmark status
                    isBookmarked = userSettings.isArticleBookmarked(article)
                }
                .onChange(of: geometry.frame(in: .global).minY) { value in
                    // Track reading progress
                    let offset = -value
                    let contentHeight = geometry.size.height
                    
                    if offset <= 0 {
                        readingProgress = 0
                    } else if offset >= contentHeight {
                        readingProgress = 1
                    } else {
                        readingProgress = min(offset / contentHeight, 1)
                    }
                }
                .navigationBarItems(
                    trailing: Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                )
            }
            .overlay(
                GeometryReader { geometry in
                    ProgressView(value: readingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: userSettings.appTheme.accentColor))
                        .frame(height: 3)
                        .frame(width: geometry.size.width)
                        .position(x: geometry.size.width / 2, y: 0)
                        .opacity(readingProgress > 0 ? 1 : 0)
                }
            )
            .sheet(isPresented: $showSafari) {
                if let url = URL(string: article.url) {
                    SafariView(url: url)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: article.url) {
                    ShareSheet(items: [url])
                }
            }
            .onTapGesture(count: 2) {
                toggleBookmark()
            }
        }
    }
    
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
    
    private func toggleBookmark() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bookmarkScale = 1.3
            isBookmarked.toggle()
        }
        
        // Animate back to normal size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bookmarkScale = 1.0
            }
        }
        
        // Update bookmarks
        if isBookmarked {
            userSettings.addBookmark(article)
        } else {
            userSettings.removeBookmark(article)
        }
    }
    
    private func estimateReadingTime() -> Int {
        let wordsPerMinute = 200
        var wordCount = article.title.split(separator: " ").count
        
        if let description = article.description {
            wordCount += description.split(separator: " ").count
        }
        
        // Simulate content words
        wordCount += 500
        
        let readingTime = max(1, Int(ceil(Double(wordCount) / Double(wordsPerMinute))))
        return readingTime
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
} 