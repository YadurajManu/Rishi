import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    let article: Article
    @State private var showSafari = false
    @State private var showShareSheet = false
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with source and date
                HStack {
                    Text(article.source.name)
                        .font(.system(size: userSettings.fontSize.textSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formattedDate(from: article.publishedAt))
                        .font(.system(size: userSettings.fontSize.textSize))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Title
                Text(article.title)
                    .font(.system(size: userSettings.fontSize.headlineSize + 4))
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Author
                if let author = article.author, !author.isEmpty {
                    Text("By \(author)")
                        .font(.system(size: userSettings.fontSize.textSize))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Image
                if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fill)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(16/9, contentMode: .fill)
                        }
                    }
                    .frame(height: 250)
                }
                
                // Description
                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: userSettings.fontSize.textSize))
                        .padding(.horizontal)
                }
                
                // Content
                if let content = article.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: userSettings.fontSize.textSize))
                        .padding(.horizontal)
                }
                
                // Region indicator
                HStack {
                    Text(userSettings.selectedCountry.flag)
                    Text("News from \(userSettings.selectedCountry.name)")
                        .font(.system(size: userSettings.fontSize.textSize - 2))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Action buttons
                HStack(spacing: 20) {
                    // Read full article button
                    Button(action: {
                        showSafari = true
                    }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Read Full Article")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    // Share button
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    
                    // Bookmark button
                    Button(action: {
                        userSettings.toggleBookmark(for: article)
                    }) {
                        HStack {
                            Image(systemName: userSettings.isArticleBookmarked(article) ? "bookmark.fill" : "bookmark")
                            Text(userSettings.isArticleBookmarked(article) ? "Saved" : "Save")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userSettings.isArticleBookmarked(article) ? Color.orange : Color.gray)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    userSettings.toggleBookmark(for: article)
                }) {
                    Image(systemName: userSettings.isArticleBookmarked(article) ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .sheet(isPresented: $showSafari) {
            SafariView(url: URL(string: article.url) ?? URL(string: "https://apple.com")!)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: article.url) {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
} 