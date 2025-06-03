import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Firestore referansı
    private let db = Firestore.firestore()
    
    // Koleksiyon yolları
    private let ideasCollection = "ideas"
    private let commentsCollection = "comments"
    
    // Firestore listener
    private var commentsListener: (() -> Void)?
    
    deinit {
        // View model destroy edildiğinde listener'ları kaldır
        commentsListener?()
    }
    
    // Yorumları yükleme
    func loadComments(for ideaId: String) {
        isLoading = true
        
        // Önceki dinleyiciyi temizle
        commentsListener?()
        
        // Firestore'dan yorumları getir
        let commentsRef = db.collection(ideasCollection).document(ideaId)
            .collection(commentsCollection)
            .order(by: "createdAt", descending: true)
        
        let listener = commentsRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Yorumlar yüklenirken hata oluştu: \(error.localizedDescription)"
                print("Yorumlar yüklenirken hata: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.comments = []
                return
            }
            
            self.comments = documents.compactMap { document -> Comment? in
                let data = document.data()
                
                // Tarihleri dönüştür
                let createdTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                let updatedTimestamp = data["updatedAt"] as? Timestamp ?? createdTimestamp
                
                return Comment(
                    id: document.documentID,
                    ideaId: ideaId,
                    authorId: data["authorId"] as? String ?? "",
                    authorName: data["authorName"] as? String ?? "",
                    content: data["content"] as? String ?? "",
                    createdAt: createdTimestamp.dateValue(),
                    updatedAt: updatedTimestamp.dateValue(),
                    likeCount: data["likeCount"] as? Int ?? 0
                )
            }
            
            print("Yorumlar yüklendi: \(self.comments.count) yorum bulundu")
        }
        
        commentsListener = { listener.remove() }
    }
    
    // Yorum ekleme
    func addComment(ideaId: String, authorId: String, authorName: String, content: String) {
        isLoading = true
        
        // Yorumun verilerini hazırla
        let commentData: [String: Any] = [
            "ideaId": ideaId,
            "authorId": authorId,
            "authorName": authorName,
            "content": content,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "likeCount": 0
        ]
        
        // Firestore işlemleri için batch oluştur
        let batch = db.batch()
        
        // Yeni yorum için referans oluştur
        let newCommentRef = db.collection(ideasCollection).document(ideaId)
            .collection(commentsCollection).document()
        
        // Fikir belgesindeki yorum sayısını güncelle
        let ideaRef = db.collection(ideasCollection).document(ideaId)
        
        // Batch'e işlemleri ekle
        batch.setData(commentData, forDocument: newCommentRef)
        batch.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: ideaRef)
        
        // Batch işlemini yürüt
        batch.commit { [weak self] error in
            self?.isLoading = false
            
            if let error = error {
                self?.errorMessage = "Yorum eklenirken hata oluştu: \(error.localizedDescription)"
                print("Yorum eklenirken hata: \(error.localizedDescription)")
                return
            }
            
            print("Yorum başarıyla eklendi")
            
            // Yorum bildirimini gönder (kendine gönderilmez)
            self?.sendCommentNotification(ideaId: ideaId, content: content)
        }
    }
    
    // Yorum güncelleme
    func updateComment(_ comment: Comment, content: String) {
        // id değeri String tipinde olduğundan, boş olup olmadığını kontrol et
        if comment.id.isEmpty {
            errorMessage = "Geçersiz yorum ID"
            return
        }
        
        let updateData: [String: Any] = [
            "content": content,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection(ideasCollection).document(comment.ideaId)
            .collection(commentsCollection).document(comment.id)
            .updateData(updateData) { [weak self] error in
                if let error = error {
                    self?.errorMessage = "Yorum güncellenirken hata oluştu: \(error.localizedDescription)"
                    print("Yorum güncellenirken hata: \(error.localizedDescription)")
                } else {
                    print("Yorum başarıyla güncellendi")
                }
            }
    }
    
    // Yorum silme
    func deleteComment(_ comment: Comment) {
        // id değeri String tipinde olduğundan, boş olup olmadığını kontrol et
        if comment.id.isEmpty {
            errorMessage = "Geçersiz yorum ID"
            return
        }
        
        // Firestore işlemleri için batch oluştur
        let batch = db.batch()
        
        // Silinecek yorum için referans
        let commentRef = db.collection(ideasCollection).document(comment.ideaId)
            .collection(commentsCollection).document(comment.id)
        
        // Fikir belgesindeki yorum sayısını güncelle
        let ideaRef = db.collection(ideasCollection).document(comment.ideaId)
        
        // Batch'e işlemleri ekle
        batch.deleteDocument(commentRef)
        batch.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: ideaRef)
        
        // Batch işlemini yürüt
        batch.commit { [weak self] error in
            if let error = error {
                self?.errorMessage = "Yorum silinirken hata oluştu: \(error.localizedDescription)"
                print("Yorum silinirken hata: \(error.localizedDescription)")
            } else {
                print("Yorum başarıyla silindi")
            }
        }
    }
    
    // Yorum beğenme
    func likeComment(_ comment: Comment) {
        // id değeri String tipinde olduğundan, boş olup olmadığını kontrol et
        if comment.id.isEmpty {
            errorMessage = "Geçersiz yorum ID"
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Beğeni için kullanıcı girişi yapılmamış"
            return
        }
        
        let commentRef = db.collection(ideasCollection).document(comment.ideaId)
            .collection(commentsCollection).document(comment.id)
        
        let likesRef = commentRef.collection("likes").document(userId)
        
        // Önce kullanıcının yorumu beğenip beğenmediğini kontrol et
        likesRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Kullanıcı zaten beğenmiş, beğeniyi kaldır
                self.unlikeComment(comment)
            } else {
                // Kullanıcı henüz beğenmemiş, beğeni ekle
                
                // Beğeni kaydı oluştur
                likesRef.setData([
                    "userId": userId,
                    "timestamp": FieldValue.serverTimestamp()
                ])
                
                // Yorum beğeni sayısını artır
                commentRef.updateData([
                    "likeCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        self.errorMessage = "Yorum beğenilirken hata oluştu: \(error.localizedDescription)"
                        print("Yorum beğenilirken hata: \(error.localizedDescription)")
                    } else {
                        print("Yorum başarıyla beğenildi")
                    }
                }
            }
        }
    }
    
    // Yorum beğenisini kaldırma
    private func unlikeComment(_ comment: Comment) {
        // id değeri String tipinde olduğundan, boş olup olmadığını kontrol et
        if comment.id.isEmpty {
            errorMessage = "Geçersiz yorum ID"
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Beğeni kaldırma için kullanıcı girişi yapılmamış"
            return
        }
        
        let commentRef = db.collection(ideasCollection).document(comment.ideaId)
            .collection(commentsCollection).document(comment.id)
        
        let likesRef = commentRef.collection("likes").document(userId)
        
        // Beğeni kaydını sil
        likesRef.delete()
        
        // Yorum beğeni sayısını azalt
        commentRef.updateData([
            "likeCount": FieldValue.increment(Int64(-1))
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Yorum beğenisi kaldırılırken hata oluştu: \(error.localizedDescription)"
                print("Yorum beğenisi kaldırılırken hata: \(error.localizedDescription)")
            } else {
                print("Yorum beğenisi başarıyla kaldırıldı")
            }
        }
    }
    
    // Yorum bildirimi gönderme
    private func sendCommentNotification(ideaId: String, content: String) {
        // Önce fikir sahibinin ID'sini al
        db.collection("ideas").document(ideaId).getDocument { [weak self] (document, error) in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let data = document.data(),
                  let authorId = data["authorId"] as? String,
                  let ideaTitle = data["title"] as? String else {
                return
            }
            
            // Kendine bildirim gönderme
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  currentUserId != authorId else {
                return
            }
            
            print("DEBUG - COMMENT NOTIFICATION - Kullanıcı ID: \(currentUserId), Fikir ID: \(ideaId)")
            
            // Firestore'dan kullanıcı adını al
            self.db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Kullanıcı bilgileri alınırken hata: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists, let userData = document.data() else {
                    print("DEBUG - HATA: Kullanıcı belgesi bulunamadı veya boş")
                    return
                }
                
                // Debug için Firestore'dan alınan tüm verileri göster
                print("DEBUG - COMMENT NOTIFICATION")
                print("Firestore'dan alınan kullanıcı verileri: \(userData)")
                
                // Kullanıcının tam adını veya kullanıcı adını al
                let firstName = userData["firstName"] as? String ?? ""
                let lastName = userData["lastName"] as? String ?? ""
                let username = userData["username"] as? String ?? ""
                
                print("DEBUG - firstName: '\(firstName)', lastName: '\(lastName)', username: '\(username)'")
                
                // Öncelik tam ad, yoksa kullanıcı adı
                let senderName = (!firstName.isEmpty && !lastName.isEmpty) ? "\(firstName) \(lastName)" : username
                
                print("DEBUG - Seçilen senderName: '\(senderName)'")
                
                // Adın boş olup olmadığını kontrol et
                if senderName.isEmpty {
                    print("DEBUG - HATA: Kullanıcı adı boş, varsayılan 'Bir kullanıcı' kullanılacak")
                }
                
                // Bildirim verilerini oluştur
                let notificationData: [String: Any] = [
                    "type": "comment",
                    "senderId": currentUserId,
                    "senderName": senderName.isEmpty ? "Bir kullanıcı" : senderName,
                    "receiverId": authorId,
                    "ideaId": ideaId,
                    "ideaTitle": ideaTitle,
                    "commentContent": content.prefix(50) + (content.count > 50 ? "..." : ""),
                    "message": "\(senderName.isEmpty ? "Bir kullanıcı" : senderName) fikrinize yorum yaptı: \(ideaTitle)",
                    "timestamp": FieldValue.serverTimestamp(),
                    "isRead": false
                ]
                
                print("DEBUG - Oluşturulan bildirim verisi: \(notificationData)")
                
                // Bildirim ekle
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Bildirim gönderilirken hata: \(error.localizedDescription)")
                    } else {
                        print("DEBUG - Yorum bildirimi başarıyla eklendi")
                    }
                }
            }
        }
    }
} 