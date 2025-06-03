import Foundation
import FirebaseFirestore
import FirebaseAuth

class FollowViewModel: ObservableObject {
    // Kullanıcının takip ettiği kişilerin ID'leri
    @Published var following: [String] = []
    
    // Kullanıcıyı takip edenlerin ID'leri
    @Published var followers: [String] = []
    
    // Takip edilen kullanıcılar
    @Published var followingUsers: [User] = []
    
    // Takipçi kullanıcılar
    @Published var followerUsers: [User] = []
    
    // Kullanıcı profili
    @Published var profileUser: User?
    
    // Yükleme durumu
    @Published var isLoading: Bool = false
    
    // Hata mesajı
    @Published var errorMessage: String?
    
    // Firestore referansı
    let db = Firestore.firestore()
    
    // Koleksiyon yolları
    private let usersCollection = "users"
    private let followingCollection = "following"
    private let followersCollection = "followers"
    
    // Firestore listener'lar
    private var followingListener: (() -> Void)?
    private var followersListener: (() -> Void)?
    
    init() {
        if let currentUserId = Auth.auth().currentUser?.uid {
            loadFollowingAndFollowers(userId: currentUserId)
        }
    }
    
    deinit {
        followingListener?()
        followersListener?()
    }
    
    // Kullanıcının takip ettikleri ve takipçilerini yükle
    func loadFollowingAndFollowers(userId: String) {
        isLoading = true
        print("Takip bilgilerini yüklüyorum, kullanıcı ID: \(userId)")
        
        // Dinleyicileri önce temizle
        followingListener?()
        followersListener?()
        
        // Takip edilenleri dinle
        let followingRef = db.collection(usersCollection).document(userId)
            .collection(followingCollection)
        
        let followingListenerTemp = followingRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Takip edilenler yüklenirken hata: \(error.localizedDescription)"
                print("Takip edilenler yüklenirken hata: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                let oldFollowing = self.following
                self.following = documents.compactMap { $0.documentID }
                
                // Takip durumu değişimini logla
                let added = Set(self.following).subtracting(Set(oldFollowing))
                let removed = Set(oldFollowing).subtracting(Set(self.following))
                
                if !added.isEmpty {
                    print("Takip listesine eklenen ID'ler: \(added)")
                }
                
                if !removed.isEmpty {
                    print("Takip listesinden çıkarılan ID'ler: \(removed)")
                }
                
                print("Takip edilen kullanıcılar yüklendi. Toplam: \(self.following.count)")
                
                // Şimdi takip edilen kullanıcıların profillerini yükle
                self.loadFollowingUsers()
            }
        }
        followingListener = { followingListenerTemp.remove() }
        
        // Takipçileri dinle
        let followersRef = db.collection(usersCollection).document(userId)
            .collection(followersCollection)
        
        let followersListenerTemp = followersRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Takipçiler yüklenirken hata: \(error.localizedDescription)"
                print("Takipçiler yüklenirken hata: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.followers = documents.compactMap { $0.documentID }
                print("Takipçi kullanıcılar yüklendi. Toplam: \(self.followers.count)")
                
                // Şimdi takipçi kullanıcıların profillerini yükle
                self.loadFollowerUsers()
            }
            
            self.isLoading = false
        }
        followersListener = { followersListenerTemp.remove() }
    }
    
    // Takip edilen kullanıcıların bilgilerini yükle
    private func loadFollowingUsers() {
        guard !following.isEmpty else {
            followingUsers = []
            return
        }
        
        // Takip edilen her bir kullanıcı için
        var users: [User] = []
        let group = DispatchGroup()
        
        for userId in following {
            group.enter()
            
            db.collection(usersCollection).document(userId).getDocument { [weak self] snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Kullanıcı bilgisi alınırken hata: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    // Tarihleri dönüştür
                    let joinTimestamp = data["joinDate"] as? Timestamp ?? Timestamp(date: Date())
                    
                    let user = User(
                        id: snapshot?.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        joinDate: joinTimestamp.dateValue(),
                        recentlyViewedIdeas: data["recentlyViewedIdeas"] as? [String] ?? [],
                        followersCount: data["followersCount"] as? Int ?? 0,
                        followingCount: data["followingCount"] as? Int ?? 0,
                        bio: data["bio"] as? String,
                        profileImageUrl: data["profileImageUrl"] as? String
                    )
                    
                    users.append(user)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.followingUsers = users
        }
    }
    
    // Takipçi kullanıcıların bilgilerini yükle
    private func loadFollowerUsers() {
        guard !followers.isEmpty else {
            followerUsers = []
            return
        }
        
        // Takipçi her bir kullanıcı için
        var users: [User] = []
        let group = DispatchGroup()
        
        for userId in followers {
            group.enter()
            
            db.collection(usersCollection).document(userId).getDocument { [weak self] snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Kullanıcı bilgisi alınırken hata: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    // Tarihleri dönüştür
                    let joinTimestamp = data["joinDate"] as? Timestamp ?? Timestamp(date: Date())
                    
                    let user = User(
                        id: snapshot?.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        joinDate: joinTimestamp.dateValue(),
                        recentlyViewedIdeas: data["recentlyViewedIdeas"] as? [String] ?? [],
                        followersCount: data["followersCount"] as? Int ?? 0,
                        followingCount: data["followingCount"] as? Int ?? 0,
                        bio: data["bio"] as? String,
                        profileImageUrl: data["profileImageUrl"] as? String
                    )
                    
                    users.append(user)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.followerUsers = users
        }
    }
    
    // Kullanıcı takip etme
    func followUser(_ userToFollow: User) {
        guard let userToFollowId = userToFollow.id,
              let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Takip için geçersiz kullanıcı ID'si veya oturum açılmamış"
            return
        }
        
        print(">>> followUser çağrıldı")
        print(">>> Takip edilecek kullanıcı: \(userToFollow.username) (ID: \(userToFollowId))")
        print(">>> Takip eden kullanıcı ID: \(currentUserId)")
        
        // Kendini takip etmeyi engelle
        if currentUserId == userToFollowId {
            print(">>> HATA: Kendini takip edemezsin")
            return
        }
        
        // Zaten takip ediliyor mu kontrol et - Öncelikle yerel listeyi kontrol ederiz
        if following.contains(userToFollowId) {
            print(">>> UYARI: Bu kullanıcı zaten takip ediliyor (yerel liste): \(userToFollowId)")
            return
        }
        
        isLoading = true
        
        // İlk olarak Firebase'de gerçekten takip ediliyor mu kontrol ediyoruz
        // Bunu yapmak, takip durumunun senkronize olmasını sağlar
        db.collection(usersCollection).document(currentUserId)
           .collection(followingCollection).document(userToFollowId)
           .getDocument { [weak self] snapshot, error in
               guard let self = self else { return }
               
               if let error = error {
                   print(">>> HATA: Takip durumu kontrol edilirken hata: \(error.localizedDescription)")
                   // Hata durumunda işlemi durdur
                   self.isLoading = false
                   return
               }
               
               // Eğer belge zaten varsa, takip zaten var demektir
               if let snapshot = snapshot, snapshot.exists {
                   print(">>> BİLGİ: Bu kullanıcı zaten takip ediliyor (Firebase): \(userToFollowId)")
                   
                   // Yerel listeyi güncelleyelim ki UI tutarlı olsun
                   if !self.following.contains(userToFollowId) {
                       // ÖNEMLİ: Firebase ile senkron olması için listeyi güncelliyoruz
                       self.following.append(userToFollowId)
                       print(">>> BİLGİ: Takip listesi Firebase ile senkronize edildi")
                   }
                   
                   self.isLoading = false
                   return
               }
               
               // Yoksa takip işlemini tamamla
               print(">>> BİLGİ: Kullanıcı takip edilmiyor, takip işlemi başlatılıyor...")
               self.completeFollowUser(currentUserId: currentUserId, userToFollowId: userToFollowId)
           }
    }
    
    // Takip işlemini tamamla
    private func completeFollowUser(currentUserId: String, userToFollowId: String) {
        print(">>> Takip işlemi başlatılıyor...")
        print(">>> Takip eden: \(currentUserId), Takip edilen: \(userToFollowId)")
        
        // UI'ı anında güncellemek için takip listesine ekle (işlem başarılı olursa)
        let wasAlreadyInList = following.contains(userToFollowId)
        if !wasAlreadyInList {
            following.append(userToFollowId)
            print(">>> Kullanıcı takip listesine geçici olarak eklendi")
        }
        
        // Kullanıcının takip ettiklerine yeni kullanıcıyı ekle
        let followingRef = db.collection(usersCollection).document(currentUserId)
            .collection(followingCollection).document(userToFollowId)
        
        // Takip edilecek kullanıcının takipçilerine mevcut kullanıcıyı ekle
        let followerRef = db.collection(usersCollection).document(userToFollowId)
            .collection(followersCollection).document(currentUserId)
        
        // Her iki kullanıcının takip sayılarını güncelle
        let currentUserRef = db.collection(usersCollection).document(currentUserId)
        let followedUserRef = db.collection(usersCollection).document(userToFollowId)
        
        // Batch işlemi oluştur
        let batch = db.batch()
        
        // Takip bilgilerini ekle
        batch.setData([
            "timestamp": FieldValue.serverTimestamp()
        ], forDocument: followingRef)
        
        batch.setData([
            "timestamp": FieldValue.serverTimestamp()
        ], forDocument: followerRef)
        
        // Takip sayılarını güncelle
        batch.updateData([
            "followingCount": FieldValue.increment(Int64(1))
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followersCount": FieldValue.increment(Int64(1))
        ], forDocument: followedUserRef)
        
        // Batch işlemini çalıştır
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                // Hata durumunda eğer eklemişsek takip listesinden çıkar
                if !wasAlreadyInList, let index = self.following.firstIndex(of: userToFollowId) {
                    self.following.remove(at: index)
                    print(">>> Hata: Takip işlemi başarısız, listeden çıkarıldı")
                }
                
                self.errorMessage = "Takip işlemi başarısız: \(error.localizedDescription)"
                print(">>> Takip işlemi başarısız: \(error.localizedDescription)")
            } else {
                print(">>> Takip işlemi başarılı, kullanıcı takip edildi: \(userToFollowId)")
                
                // Takipçi ve takip edilen kullanıcı listelerini güncelle
                self.loadFollowingUsers()
                
                // Takip bildirimini gönder
                self.sendFollowNotification(userToFollowId: userToFollowId)
            }
        }
    }
    
    // Kullanıcı takibi bırakma
    func unfollowUser(_ userToUnfollow: User) {
        guard let userToUnfollowId = userToUnfollow.id,
              let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Takipten çıkmak için geçersiz kullanıcı ID'si veya oturum açılmamış"
            return
        }
        
        print(">>> unfollowUser çağrıldı")
        print(">>> Takipten çıkarılacak kullanıcı: \(userToUnfollow.username) (ID: \(userToUnfollowId))")
        print(">>> Takipten çıkaran kullanıcı ID: \(currentUserId)")
        
        // Kendini takipten çıkarmayı engelle
        if currentUserId == userToUnfollowId {
            print(">>> HATA: Kendini takipten çıkaramazsın")
            return
        }
        
        // Zaten takip etmiyor mu kontrol et - Öncelikle yerel listeyi kontrol ederiz
        if !following.contains(userToUnfollowId) {
            print(">>> UYARI: Bu kullanıcı zaten takip edilmiyor (yerel liste): \(userToUnfollowId)")
            return
        }
        
        isLoading = true
        
        // İlk olarak Firebase'de gerçekten takip ediliyor mu kontrol ediyoruz
        db.collection(usersCollection).document(currentUserId)
           .collection(followingCollection).document(userToUnfollowId)
           .getDocument { [weak self] snapshot, error in
               guard let self = self else { return }
               
               if let error = error {
                   print(">>> HATA: Takip durumu kontrol edilirken hata: \(error.localizedDescription)")
                   // Hata durumunda işlemi durdur
                   self.isLoading = false
                   return
               }
               
               // Eğer belge yoksa, takip zaten yok demektir
               if let snapshot = snapshot, !snapshot.exists {
                   print(">>> BİLGİ: Bu kullanıcı zaten takip edilmiyor (Firebase): \(userToUnfollowId)")
                   
                   // Yerel listeyi güncelleyelim ki UI tutarlı olsun
                   if let index = self.following.firstIndex(of: userToUnfollowId) {
                       // ÖNEMLİ: Firebase ile senkron olması için listeyi güncelliyoruz
                       self.following.remove(at: index)
                       print(">>> BİLGİ: Takip listesi Firebase ile senkronize edildi")
                   }
                   
                   self.isLoading = false
                   return
               }
               
               // Varsa takipten çıkma işlemini tamamla
               print(">>> BİLGİ: Kullanıcı takip ediliyor, takipten çıkma işlemi başlatılıyor...")
               self.completeUnfollowUser(currentUserId: currentUserId, userToUnfollowId: userToUnfollowId)
           }
    }
    
    // Takipten çıkma işlemini tamamla
    private func completeUnfollowUser(currentUserId: String, userToUnfollowId: String) {
        print(">>> Takipten çıkma işlemi başlatılıyor...")
        print(">>> Takipten çıkan: \(currentUserId), Takipten çıkarılan: \(userToUnfollowId)")
        
        // UI'ı anında güncellemek için takip listesinden çıkar (işlem başarılı olursa)
        let indexInList = following.firstIndex(of: userToUnfollowId)
        if let indexInList = indexInList {
            let removedItem = following.remove(at: indexInList)
            print(">>> Kullanıcı takip listesinden geçici olarak çıkarıldı: \(removedItem)")
        } else {
            print(">>> Kullanıcı zaten takip listesinde yok")
        }
        
        // Kullanıcının takip ettiklerinden kullanıcıyı çıkar
        let followingRef = db.collection(usersCollection).document(currentUserId)
            .collection(followingCollection).document(userToUnfollowId)
        
        // Takibi bırakılan kullanıcının takipçilerinden mevcut kullanıcıyı çıkar
        let followerRef = db.collection(usersCollection).document(userToUnfollowId)
            .collection(followersCollection).document(currentUserId)
        
        // Her iki kullanıcının takip sayılarını güncelle
        let currentUserRef = db.collection(usersCollection).document(currentUserId)
        let unfollowedUserRef = db.collection(usersCollection).document(userToUnfollowId)
        
        // Batch işlemi oluştur
        let batch = db.batch()
        
        // Takip bilgilerini sil
        batch.deleteDocument(followingRef)
        batch.deleteDocument(followerRef)
        
        // Takip sayılarını güncelle
        batch.updateData([
            "followingCount": FieldValue.increment(Int64(-1))
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "followersCount": FieldValue.increment(Int64(-1))
        ], forDocument: unfollowedUserRef)
        
        // Batch işlemini çalıştır
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                // Hata durumunda takip listesine geri ekle (eğer çıkarmışsak)
                if indexInList != nil && !self.following.contains(userToUnfollowId) {
                    self.following.append(userToUnfollowId)
                    print(">>> Hata: Takipten çıkma başarısız, listeye geri eklendi")
                }
                
                self.errorMessage = "Takipten çıkma işlemi başarısız: \(error.localizedDescription)"
                print(">>> Takipten çıkma işlemi başarısız: \(error.localizedDescription)")
            } else {
                print(">>> Takipten çıkma işlemi başarılı, kullanıcı takipten çıkarıldı: \(userToUnfollowId)")
                
                // Takipçi ve takip edilen kullanıcı listelerini güncelle
                self.loadFollowingUsers()
            }
        }
    }
    
    // Kullanıcının belirli bir kullanıcıyı takip edip etmediğini kontrol etme
    func isFollowing(userId: String) -> Bool {
        return following.contains(userId)
    }
    
    // Takip bildirimi gönderme
    private func sendFollowNotification(userToFollowId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Firestore'dan kullanıcı adını al
        db.collection(usersCollection).document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Kullanıcı bilgileri alınırken hata: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("Kullanıcı belgesi bulunamadı")
                return
            }
            
            // Debug için Firestore'dan alınan tüm verileri göster
            print("DEBUG - FOLLOW NOTIFICATION")
            print("Firestore'dan alınan kullanıcı verileri: \(data)")
            
            // Kullanıcının tam adını veya kullanıcı adını al
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            
            print("DEBUG - firstName: '\(firstName)', lastName: '\(lastName)', username: '\(username)'")
            
            // Öncelik tam ad, yoksa kullanıcı adı
            let senderName = (!firstName.isEmpty && !lastName.isEmpty) ? "\(firstName) \(lastName)" : username
            
            print("DEBUG - Seçilen senderName: '\(senderName)'")
            
            // Bildirim verilerini oluştur
            let notificationData: [String: Any] = [
                "type": "follow",
                "senderId": currentUserId,
                "senderName": senderName,
                "receiverId": userToFollowId,
                "message": "\(senderName) sizi takip etmeye başladı",
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false
            ]
            
            print("DEBUG - Oluşturulan bildirim verisi: \(notificationData)")
            
            // Bildirim ekle
            self.db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("Takip bildirimi gönderilirken hata: \(error.localizedDescription)")
                } else {
                    print("DEBUG - Takip bildirimi başarıyla eklendi")
                }
            }
        }
    }
    
    // ID'ye göre kullanıcı bilgilerini getir
    func fetchUserById(_ userId: String, completion: @escaping (User?) -> Void) {
        isLoading = true
        
        db.collection(usersCollection).document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Kullanıcı bilgisi alınırken hata: \(error.localizedDescription)"
                print("Kullanıcı bilgisi alınırken hata: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "Kullanıcı bulunamadı"
                completion(nil)
                return
            }
            
            // Tarihleri dönüştür
            let joinTimestamp = data["joinDate"] as? Timestamp ?? Timestamp(date: Date())
            
            let user = User(
                id: snapshot?.documentID,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                firstName: data["firstName"] as? String ?? "",
                lastName: data["lastName"] as? String ?? "",
                joinDate: joinTimestamp.dateValue(),
                recentlyViewedIdeas: data["recentlyViewedIdeas"] as? [String] ?? [],
                followersCount: data["followersCount"] as? Int ?? 0,
                followingCount: data["followingCount"] as? Int ?? 0,
                bio: data["bio"] as? String,
                profileImageUrl: data["profileImageUrl"] as? String
            )
            
            self.profileUser = user
            completion(user)
        }
    }
    
    // Mevcut kullanıcının çift takip sorunlarını temizle
    func cleanupDuplicateFollows() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Takip edilen kullanıcıların ID'lerini al
        let followingIds = Set(following)
        
        // Firebase'de takip edilen kullanıcıları kontrol et
        db.collection(usersCollection).document(currentUserId)
            .collection(followingCollection).getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Takip listesi kontrol edilirken hata: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Firebase'de var ama yerel listede olmayan kullanıcıları ekle
                for doc in documents {
                    let userId = doc.documentID
                    if !followingIds.contains(userId) {
                        self.following.append(userId)
                        print("Eksik takip tespit edildi: \(userId)")
                    }
                }
                
                print("Takip listesi temizlendi. Güncel takip edilen sayısı: \(self.following.count)")
            }
    }
} 
 