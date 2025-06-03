import SwiftUI

struct IdeaCard: View {
    let idea: Idea
    let onLike: () -> Void
    let onTap: () -> Void
    let isLiked: Bool
    
    @State private var animateOnAppear = false
    
    var body: some View {
        ModernCardView(backgroundColor: Color.themeBackground, cornerRadius: 16, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Üst bölüm: Başlık ve kategori
                VStack(alignment: .leading, spacing: 8) {
                    // Başlık çubuğu
                    HStack {
                        Text(idea.title)
                            .font(.headline)
                            .foregroundColor(.themeTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Kategori etiketi
                        Text(idea.category)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundColor(Color.categoryColor(getCategoryColor(idea.category)))
                            .background(Color.categoryColor(getCategoryColor(idea.category)).opacity(0.12))
                            .cornerRadius(8)
                    }
                    
                    // Açıklama
                    Text(idea.description)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Alt bölüm: Etkileşimler ve yazar bilgisi
                HStack {
                    // Beğeni butonu ve sayısı
                    HStack(spacing: 4) {
                        Button(action: onLike) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(.themeAccent)
                                .imageScale(.medium)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Text("\(idea.likeCount)")
                            .font(.footnote)
                            .foregroundColor(.themeTextSecondary)
                    }
                    
                    // Yorum sayısı
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.themeTextSecondary)
                            .imageScale(.small)
                        
                        Text("\(idea.commentCount)")
                            .font(.footnote)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding(.leading, 8)
                    
                    // Görüntülenme sayısı
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .foregroundColor(.themeTextSecondary)
                            .imageScale(.small)
                        
                        Text("\(idea.viewCount)")
                            .font(.footnote)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Yazar ve tarih
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.themeTextSecondary)
                            .imageScale(.small)
                        
                        Text(idea.authorName)
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                        
                        Text(timeAgoSinceDate(idea.createdAt))
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .onTapGesture {
            onTap()
        }
        .opacity(animateOnAppear ? 1 : 0)
        .offset(y: animateOnAppear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateOnAppear = true
            }
        }
    }
    
    // İnit ekle
    init(idea: Idea, onLike: @escaping () -> Void, onTap: @escaping () -> Void, isLiked: Bool = false) {
        self.idea = idea
        self.onLike = onLike
        self.onTap = onTap
        self.isLiked = isLiked
    }
    
    // Kategori adına göre uygun renk ismi döndürür
    private func getCategoryColor(_ categoryName: String) -> String {
        switch categoryName {
        case "Teknoloji": return "blue"
        case "Eğitim": return "green"
        case "Sağlık": return "red"
        case "Çevre": return "mint"
        case "Tarım": return "yellow"
        case "Sanat": return "purple"
        case "Spor": return "orange"
        default: return "gray"
        }
    }
    
    // Tarih formatlama
    private func timeAgoSinceDate(_ date: Date) -> String {
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
            onTap: {},
            isLiked: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 