import SwiftUI

struct CommentView: View {
    let comment: Comment
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onLike: () -> Void
    var isCurrentUserAuthor: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık satırı
            HStack {
                // Yazar bilgisi
                HStack {
                    Image(systemName: "person.circle")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // İşlemler menüsü (sadece yorum sahibi için)
                if isCurrentUserAuthor {
                    Menu {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Label("Düzenle", systemImage: "pencil")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
            }
            
            // Yorum içeriği
            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)
            
            // Alt bilgi satırı
            HStack {
                // Tarih bilgisi
                Text(timeAgoDisplay(date: comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Beğeni butonu
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text("\(comment.likeCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Tarih formatlama yardımcı fonksiyon
    private func timeAgoDisplay(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        CommentView(
            comment: Comment.example,
            onDelete: {},
            onEdit: {},
            onLike: {},
            isCurrentUserAuthor: true
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 