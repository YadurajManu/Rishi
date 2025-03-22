import SwiftUI

struct ArticleCard: View {
    let article: Article
    @EnvironmentObject private var userSettings: UserSettings
    
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
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(article.source.name)
                        .font(.system(size: userSettings.fontSize.textSize - 2))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formattedDate(from: article.publishedAt))
                        .font(.system(size: userSettings.fontSize.textSize - 2))
                        .foregroundColor(.secondary)
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
                
                // Author line
                if let author = article.author, !author.isEmpty {
                    Text("By \(author)")
                        .font(.system(size: userSettings.fontSize.textSize - 2))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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