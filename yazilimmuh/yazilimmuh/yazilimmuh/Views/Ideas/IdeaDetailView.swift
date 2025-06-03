import SwiftUI

struct IdeaDetailView: View {
    let idea: Idea
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var commentsViewModel = CommentsViewModel()
    @StateObject private var followViewModel = FollowViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditIdea = false
    @State private var showingDeleteAlert = false
    @State private var commentText = ""
    @State private var isLoadingProfile = false
    @State private var authorProfile: User?
    @State private var showingProfile = false
    
    @State private var localLikeCount: Int = 0
    @State private var isLiked: Bool = false
    
    // Yorum düzenleme için durum değişkenleri
    @State private var editingComment: Comment? = nil
    @State private var editCommentText: String = ""
    @State private var isEditingComment = false
    
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
                            // Önce UI'ı güncelle (hızlı tepki)
                            if isLiked {
                                localLikeCount -= 1
                            } else {
                                localLikeCount += 1
                            }
                            isLiked.toggle()
                            
                            // Sonra Firestore'a güncelleme gönder
                            viewModel.likeIdea(idea)
                            
                            // Log ekleyelim
                            print("Beğeni durumu değişti: \(isLiked ? "Beğenildi" : "Beğeni kaldırıldı"), Sayaç: \(localLikeCount)")
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                        }
                        
                        Text("\(localLikeCount) beğeni")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                    
                    // Görüntülenme sayısı
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .foregroundColor(.gray)
                        
                        Text("\(idea.viewCount) görüntülenme")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Yazar bilgisi
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            loadAuthorProfile()
                        }) {
                            Text(idea.authorName)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoadingProfile)
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
                                editingComment = comment
                                editCommentText = comment.content
                                isEditingComment = true
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
            if let ideaId = idea.id {
                commentsViewModel.loadComments(for: ideaId)
            }
            
            // Beğeni durumu ve sayısı için başlangıç değerleri
            localLikeCount = idea.likeCount
            isLiked = viewModel.isIdeaLikedByUser(idea.id ?? "")
            print("Fikir yüklendi - Beğeni durumu: \(isLiked), Beğeni sayısı: \(localLikeCount)")
            
            // Son görüntülenen fikirler listesine ekle
            viewModel.viewIdea(idea)
        }
        .onReceive(viewModel.$ideas) { _ in
            // ViewModel'deki fikirler güncellendiğinde, mevcut fikirin beğeni sayısını güncelle
            if let ideaId = idea.id, let updatedIdea = viewModel.ideas.first(where: { $0.id == ideaId }) {
                localLikeCount = updatedIdea.likeCount
                print("Fikirler listesi güncellendi - Yeni beğeni sayısı: \(localLikeCount)")
            }
            
            // Beğeni durumunu kontrol et
            if let ideaId = idea.id {
                isLiked = viewModel.isIdeaLikedByUser(ideaId)
                print("Beğeni durumu güncellendi: \(isLiked)")
            }
        }
        .sheet(isPresented: $showingEditIdea) {
            AddEditIdeaView(
                viewModel: viewModel,
                authorId: idea.authorId,
                authorName: idea.authorName,
                ideaToEdit: idea
            )
        }
        .sheet(isPresented: $showingProfile) {
            if let user = authorProfile {
                NavigationView {
                    ProfileView(
                        user: user,
                        isCurrentUser: authViewModel.currentUser?.id == user.id,
                        authViewModel: authViewModel,
                        followViewModel: followViewModel,
                        ideasViewModel: viewModel
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kapat") {
                                showingProfile = false
                            }
                        }
                    }
                }
            }
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
        // Yorum düzenleme sheet'i
        .sheet(isPresented: $isEditingComment) {
            NavigationView {
                VStack {
                    TextField("Yorumunuz", text: $editCommentText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("Yorumu Düzenle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") {
                            isEditingComment = false
                            editingComment = nil
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            if let comment = editingComment, !editCommentText.isEmpty {
                                commentsViewModel.updateComment(comment, content: editCommentText)
                                isEditingComment = false
                                editingComment = nil
                            }
                        }
                        .disabled(editCommentText.isEmpty)
                    }
                }
            }
        }
    }
    
    // Yorum ekleme
    private func addComment() {
        guard let currentUser = authViewModel.currentUser, 
              let userId = currentUser.id,
              let ideaId = idea.id,
              !commentText.isEmpty else { return }
        
        commentsViewModel.addComment(
            ideaId: ideaId,
            authorId: userId,
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
        guard let currentUser = authViewModel.currentUser, 
              let userId = currentUser.id else { return false }
        return userId == idea.authorId
    }
    
    // Kullanıcının yorum sahibi olup olmadığını kontrol etme
    private func isCurrentUserCommentAuthor(_ comment: Comment) -> Bool {
        guard let currentUser = authViewModel.currentUser,
              let userId = currentUser.id else { return false }
        return userId == comment.authorId
    }
    
    private func loadAuthorProfile() {
        guard !idea.authorId.isEmpty else { return }
        
        isLoadingProfile = true
        followViewModel.fetchUserById(idea.authorId) { user in
            self.authorProfile = user
            self.isLoadingProfile = false
            self.showingProfile = true
        }
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