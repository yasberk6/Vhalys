import SwiftUI

struct IdeaDetailView: View {
    let idea: Idea
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var commentsViewModel = CommentsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditIdea = false
    @State private var showingDeleteAlert = false
    @State private var commentText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Fikir başlığı
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(idea.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Fikir sahibi ise düzenle/sil menüsü
                        if isCurrentUserAuthor {
                            Menu {
                                Button(action: {
                                    showingEditIdea = true
                                }) {
                                    Label("Düzenle", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    showingDeleteAlert = true
                                }) {
                                    Label("Sil", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                        }
                    }
                    
                    HStack {
                        Text(idea.category)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        // Tarih bilgisi
                        Text(formattedDate(idea.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Fikir içeriği
                Text(idea.description)
                    .font(.body)
                
                // İstatistikler
                HStack {
                    // Beğeni sayısı
                    HStack(spacing: 4) {
                        Button(action: {
                            viewModel.likeIdea(idea)
                        }) {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                        }
                        
                        Text("\(idea.likeCount) beğeni")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Yazar bilgisi
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.gray)
                        
                        Text(idea.authorName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Yorumlar başlığı
                Text("Yorumlar")
                    .font(.headline)
                
                // Yorum ekleme alanı
                VStack {
                    HStack {
                        TextField("Yorumunuzu yazın...", text: $commentText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        
                        Button(action: addComment) {
                            Image(systemName: "paperplane.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(commentText.isEmpty)
                    }
                }
                
                // Yorumlar listesi
                if commentsViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if commentsViewModel.comments.isEmpty {
                    Text("Henüz yorum yapılmamış. İlk yorumu siz yapın!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(commentsViewModel.comments) { comment in
                        CommentView(
                            comment: comment,
                            onDelete: isCurrentUserCommentAuthor(comment) ? {
                                commentsViewModel.deleteComment(comment)
                            } : nil,
                            onEdit: isCurrentUserCommentAuthor(comment) ? {
                                // Burada yorum düzenleme yapılabilir
                            } : nil,
                            onLike: {
                                commentsViewModel.likeComment(comment)
                            },
                            isCurrentUserAuthor: isCurrentUserCommentAuthor(comment)
                        )
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Fikir Detayı")
                    .font(.headline)
            }
        }
        .onAppear {
            // Yorumları yükle
            commentsViewModel.loadComments(for: idea.id)
            
            // Son görüntülenen fikirler listesine ekle
            viewModel.viewIdea(idea)
        }
        .sheet(isPresented: $showingEditIdea) {
            AddEditIdeaView(
                viewModel: viewModel,
                authorId: idea.authorId,
                authorName: idea.authorName,
                ideaToEdit: idea
            )
        }
        .alert("Fikir Silinsin Mi?", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel.deleteIdea(idea)
                dismiss()
            }
        } message: {
            Text("Bu fikri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
    }
    
    // Yorum ekleme
    private func addComment() {
        guard let currentUser = authViewModel.currentUser, !commentText.isEmpty else { return }
        
        commentsViewModel.addComment(
            ideaId: idea.id,
            authorId: currentUser.id,
            authorName: currentUser.username,
            content: commentText
        )
        
        commentText = ""
    }
    
    // Tarih formatla
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Kullanıcının fikir sahibi olup olmadığını kontrol etme
    private var isCurrentUserAuthor: Bool {
        guard let currentUser = authViewModel.currentUser else { return false }
        return currentUser.id == idea.authorId
    }
    
    // Kullanıcının yorum sahibi olup olmadığını kontrol etme
    private func isCurrentUserCommentAuthor(_ comment: Comment) -> Bool {
        guard let currentUser = authViewModel.currentUser else { return false }
        return currentUser.id == comment.authorId
    }
}

struct IdeaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdeaDetailView(
                idea: Idea.example,
                viewModel: IdeasViewModel(),
                authViewModel: AuthViewModel()
            )
        }
    }
} 