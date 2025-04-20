import Foundation
import SwiftUI

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Yorumları yükleme
    func loadComments(for ideaId: String) {
        isLoading = true
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için test verileri kullanıyoruz
        
        // Test için yorum verilerini yükleyelim
        if ideaId == "idea1" {
            comments = Comment.examples
        } else {
            comments = []
        }
        
        isLoading = false
    }
    
    // Yorum ekleme
    func addComment(ideaId: String, authorId: String, authorName: String, content: String) {
        let newComment = Comment(
            id: UUID().uuidString,
            ideaId: ideaId,
            authorId: authorId,
            authorName: authorName,
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            likeCount: 0
        )
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        comments.insert(newComment, at: 0)
    }
    
    // Yorum güncelleme
    func updateComment(_ comment: Comment, content: String) {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        
        var updatedComment = comment
        updatedComment.content = content
        updatedComment.updatedAt = Date()
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        comments[index] = updatedComment
    }
    
    // Yorum silme
    func deleteComment(_ comment: Comment) {
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        comments.removeAll { $0.id == comment.id }
    }
    
    // Yorum beğenme
    func likeComment(_ comment: Comment) {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        
        var updatedComment = comment
        updatedComment.likeCount += 1
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        comments[index] = updatedComment
    }
} 