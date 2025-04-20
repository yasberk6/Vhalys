import SwiftUI

struct IdeaCard: View {
    let idea: Idea
    var onLike: () -> Void
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık ve kategori
            HStack {
                Text(idea.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                Text(idea.category)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            // Açıklama
            Text(idea.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Divider()
            
            // Alt bilgi satırı
            HStack {
                // Yazar bilgisi
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.gray)
                    
                    Text(idea.authorName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Beğeni sayısı
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                        
                        Text("\(idea.likeCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Yorum sayısı
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.blue)
                    
                    Text("\(idea.commentCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Zaman bilgisi
            HStack {
                Spacer()
                
                Text(timeAgoDisplay(date: idea.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    // Tarih formatlama yardımcı fonksiyon
    private func timeAgoDisplay(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct IdeaCard_Previews: PreviewProvider {
    static var previews: some View {
        IdeaCard(
            idea: Idea.example,
            onLike: {},
            onTap: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 