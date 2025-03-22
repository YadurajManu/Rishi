import SwiftUI
import UIKit

struct ArticleCard: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    @State private var isBookmarked: Bool = false
    @State private var bookmarkScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = article.urlToImage, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 180)
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                .cornerRadius(8)
                            )
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                            .cornerRadius(8)
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 180)
                            .cornerRadius(8)
                    }
                }
                .cornerRadius(8)
                .overlay(
                    ZStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                toggleBookmark()
                            }) {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(isBookmarked ? .yellow : .white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .scaleEffect(bookmarkScale)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .padding(12)
                        }
                        
                        VStack {
                            Spacer()
                            HStack {
                                Text(article.source.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                    .padding(8)
                                
                                Spacer()
                            }
                        }
                    }
                )
                .onTapGesture(count: 2) {
                    toggleBookmark()
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(formattedDate(from: article.publishedAt))
                        .font(.system(size: userSettings.fontSize.textSize - 2))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(timeBasedColor(from: article.publishedAt))
                            .frame(width: 8, height: 8)
                        
                        Text(timeAgo(from: article.publishedAt))
                            .font(.system(size: userSettings.fontSize.textSize - 2))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                
                Text(article.title)
                    .font(.system(size: userSettings.fontSize.headlineSize))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
                
                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: userSettings.fontSize.textSize))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Bottom info row
                HStack {
                    if let author = article.author, !author.isEmpty {
                        Text("By \(author)")
                            .font(.system(size: userSettings.fontSize.textSize - 2))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Reading time estimate
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(estimateReadingTime(title: article.title, description: article.description)) min read")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .onAppear {
            // Check if article is bookmarked
            isBookmarked = userSettings.isArticleBookmarked(article)
        }
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
    
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
    
    private func timeAgo(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else {
            return "Just now"
        }
    }
    
    private func timeBasedColor(from dateString: String) -> Color {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return .gray
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour], from: date, to: now)
        
        if let hours = components.hour {
            if hours < 2 {
                return .red
            } else if hours < 12 {
                return .orange
            } else if hours < 24 {
                return .blue
            }
        }
        
        return .gray
    }
    
    private func estimateReadingTime(title: String, description: String?) -> Int {
        let wordsPerMinute = 200
        var wordCount = title.split(separator: " ").count
        
        if let desc = description {
            wordCount += desc.split(separator: " ").count
        }
        
        let readingTime = max(1, Int(ceil(Double(wordCount) / Double(wordsPerMinute))))
        return readingTime
    }
} 