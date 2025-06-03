import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// NotificationViewModel içinde zaten tanımlanmış olan ListenerRegistration tipini kullan
// typealias ListenerRegistration = (() -> Void)

class IdeasViewModel: ObservableObject {
    @Published var ideas: [Idea] = []
    @Published var categories: [Category] = Category.examples
    @Published var selectedCategory: Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recentlyViewedIdeas: [Idea] = []
    @Published var userLikedIdeas: Set<String> = [] // Kullanıcının beğendiği fikirler
    
    // Arama ile ilgili değişkenler
    @Published var searchText: String = ""
    @Published var searchResults: [Idea] = []
    @Published var isSearching: Bool = false
    @Published var lastSearchQuery: String = ""
    
    // Akış türü
    @Published var feedType: FeedType = .forYou
    
    // Takip edilen kullanıcıların ID'leri
    @Published var followingUserIds: [String] = []
    
    // Akış türleri
    enum FeedType {
        case forYou       // Senin için (tüm fikirler)
        case following    // Takip ettiklerin
    }
    
    // Firestore referansı
    private let db = Firestore.firestore()
    
    // Koleksiyon yolları
    private let ideasCollection = "ideas"
    private let likesCollection = "likes"
    private let usersCollection = "users"
    
    // Maksimum son bakılan fikir sayısı
    private let maxRecentlyViewedCount = 5
    
    // Firestore listener'lar için temizleme fonksiyonları
    private var ideasListener: (() -> Void)? = nil
    private var userLikesListener: (() -> Void)? = nil
    
    init() {
        fetchCategories()
        subscribeToIdeas()
        subscribeToUserLikes()
        fetchFollowingUserIds()
    }
    
    deinit {
        // View model destroy edildiğinde listener'ları kaldır
        ideasListener?()
        userLikesListener?()
    }
    
    // Kullanıcının beğendiği fikirleri dinle
    private func subscribeToUserLikes() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("Beğenileri dinlemek için kullanıcı girişi gerekli")
            return 
        }
        
        let listener = db.collection(usersCollection).document(userId)
            .collection(likesCollection)
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Beğenilen fikirler yüklenirken hata: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    // Beğenilen fikirlerin ID'lerini kaydet
                    self.userLikedIdeas = Set(snapshot.documents.compactMap { $0.documentID })
                    print("Beğenilen fikirler güncellendi: \(self.userLikedIdeas.count) fikir")
                }
            }
        
        userLikesListener = { listener.remove() }
    }
    
    // Fikirleri Firestore'dan getir ve değişiklikleri dinle
    private func subscribeToIdeas() {
        isLoading = true
        
        var query: Query = db.collection(ideasCollection)
            .order(by: "createdAt", descending: true)
        
        // Eğer bir kategori seçiliyse, sorguyu filtreleme
        if let selectedCategory = selectedCategory {
            query = query.whereField("category", isEqualTo: selectedCategory.name)
        }
        
        // Limit ekle - performans için önemli
        query = query.limit(to: 50)
        
        let listener = query.addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Fikirler yüklenirken hata oluştu: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Firestore'dan veri alınamadı"
                    return
                }
                
                self.ideas = documents.compactMap { document -> Idea? in
                    let data = document.data()
                    
                    // Tarihleri dönüştür
                    let createdTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    let updatedTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
                    let viewedTimestamp = data["viewedAt"] as? Timestamp
                    
                    let idea = Idea(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "",
                        category: data["category"] as? String ?? "",
                        createdAt: createdTimestamp.dateValue(),
                        updatedAt: updatedTimestamp.dateValue(),
                        likeCount: data["likeCount"] as? Int ?? 0,
                        commentCount: data["commentCount"] as? Int ?? 0,
                    viewCount: data["viewCount"] as? Int ?? 0,
                        viewedAt: viewedTimestamp?.dateValue()
                    )
                    
                    return idea
                }
                
                // Son bakılan fikirler listesini güncelle
                self.updateRecentlyViewedIdeasAfterFetch()
            }
        
        // Listener'ı fonksiyon olarak sakla
        ideasListener = { listener.remove() }
    }
    
    // Son bakılan fikirler listesini güncelle
    private func updateRecentlyViewedIdeasAfterFetch() {
        // Mevcut son bakılan fikirlerin ID'lerini al
        let recentIds = recentlyViewedIdeas.map { $0.id }
        
        // Son bakılan fikirleri güncel verilerle eşleştir
        recentlyViewedIdeas = recentIds.compactMap { recentId in
            ideas.first { $0.id == recentId }
        }
    }
    
    // Kategorileri Firestore'dan getir
    func fetchCategories() {
        // Şimdilik kategorileri statik olarak kullanıyoruz
        // İleriki aşamalarda Firestore'dan kategoriler de getirilebilir
        self.categories = Category.examples
    }
    
    // Fikir görüntüleme (fikir detayına bakıldığında çağrılır)
    func viewIdea(_ idea: Idea) {
        guard let id = idea.id, let userId = Auth.auth().currentUser?.uid else { return }

        // İlk önce fikri güncelle (görüntülenme tarihini ekle)
        var updatedIdea = idea
        updatedIdea.viewedAt = Date()
        
        // Kullanıcının bu fikri daha önce görüntüleyip görüntülemediğini kontrol et
        let viewedRef = db.collection(ideasCollection).document(id)
            .collection("views").document(userId)
        
        viewedRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Kullanıcı bu fikri daha önce görüntülemiş, sadece tarih güncellenir
                viewedRef.updateData(["timestamp": Timestamp(date: Date())])
            } else {
                // Kullanıcı bu fikri ilk kez görüntülüyor
                
                // Firestore'da fikri güncelle - görüntülenme sayısını artır
                let ideaRef = self.db.collection(self.ideasCollection).document(id)
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        // Fikirle ilgili belgeyi al
                        let document = try transaction.getDocument(ideaRef)
                        
                        // Mevcut görüntülenme sayısını al ve artır
                        let currentViewCount = document.data()?["viewCount"] as? Int ?? 0
                        transaction.updateData(["viewCount": currentViewCount + 1,
                                                "viewedAt": Timestamp(date: Date())], forDocument: ideaRef)
                        
                        // Görüntüleme kaydını yeni kullanıcı için oluştur
                        transaction.setData(["timestamp": Timestamp(date: Date()),
                                           "userName": Auth.auth().currentUser?.displayName ?? "Anonim"], 
                                           forDocument: viewedRef)
                        
                        return nil
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                }) { (_, error) in
                if let error = error {
                        print("Görüntülenme sayısı güncellenirken hata: \(error.localizedDescription)")
                    }
            }
        }
        
        // Zaten listenin en başındaysa bir şey yapma
            if let firstIndex = self.recentlyViewedIdeas.firstIndex(where: { $0.id == idea.id }),
           firstIndex == 0 {
            return
        }
        
        // Fikir zaten listede varsa, listeden çıkar
            self.recentlyViewedIdeas.removeAll(where: { $0.id == idea.id })
        
        // Fikri listenin en başına ekle
            self.recentlyViewedIdeas.insert(updatedIdea, at: 0)
        
        // Liste maksimum boyutu aşıyorsa sondan kırp
            if self.recentlyViewedIdeas.count > self.maxRecentlyViewedCount {
                self.recentlyViewedIdeas = Array(self.recentlyViewedIdeas.prefix(self.maxRecentlyViewedCount))
        }
        
        // Kullanıcının son baktığı fikirleri Firestore'a kaydet
            self.saveRecentlyViewedIdeas()
        }
    }
    
    // Kullanıcının son baktığı fikirleri Firestore'a kaydet
    private func saveRecentlyViewedIdeas() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let recentIds = recentlyViewedIdeas.compactMap { $0.id }
        
        db.collection(usersCollection).document(userId).updateData([
            "recentlyViewedIdeas": recentIds
        ]) { error in
            if let error = error {
                print("Son bakılan fikirler kaydedilirken hata: \(error.localizedDescription)")
            }
        }
    }
    
    // Son bakılan fikirleri getir
    func getRecentlyViewedIdeas() -> [Idea] {
        return recentlyViewedIdeas
    }
    
    // Fikir ekleme
    func addIdea(title: String, description: String, category: String, authorId: String, authorName: String) {
        isLoading = true
        
        let newIdeaRef = db.collection(ideasCollection).document()
        
        let newIdeaData: [String: Any] = [
            "title": title,
            "description": description,
            "authorId": authorId,
            "authorName": authorName,
            "category": category,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "likeCount": 0,
            "commentCount": 0,
            "viewCount": 0  // Görüntülenme sayısı ekle
        ]
        
        newIdeaRef.setData(newIdeaData) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Fikir eklenirken hata oluştu: \(error.localizedDescription)"
            } else {
                // Yeni fikir için kategori istatistiklerini güncelle
                self.incrementCategoryCount(category)
            }
        }
    }
    
    // Kategori istatistiklerini güncelle
    private func incrementCategoryCount(_ categoryName: String) {
        let categoryRef = db.collection("categories").document(categoryName)
        
        categoryRef.updateData([
            "ideaCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Kategori istatistikleri güncellenirken hata: \(error.localizedDescription)")
                
                // Belge yoksa oluştur
                categoryRef.setData([
                    "name": categoryName,
                    "ideaCount": 1
                ])
            }
        }
    }
    
    // Fikir güncelleme
    func updateIdea(_ idea: Idea, title: String, description: String, category: String) {
        guard let id = idea.id else {
            errorMessage = "Geçersiz fikir ID'si"
            return
        }
        
        isLoading = true
        
        let ideaRef = db.collection(ideasCollection).document(id)
        
        // Kategori değiştiyse, kategori istatistiklerini güncelle
        if idea.category != category {
            // Eski kategoriden azalt
            db.collection("categories").document(idea.category).updateData([
                "ideaCount": FieldValue.increment(Int64(-1))
            ])
            
            // Yeni kategoriye ekle
            incrementCategoryCount(category)
        }
        
        let updateData: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "updatedAt": Timestamp(date: Date())
        ]
        
        ideaRef.updateData(updateData) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Fikir güncellenirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
    
    // Fikir silme
    func deleteIdea(_ idea: Idea) {
        guard let id = idea.id else {
            errorMessage = "Geçersiz fikir ID'si"
            return
        }
        
        isLoading = true
        
        let batch = db.batch()
        let ideaRef = db.collection(ideasCollection).document(id)
        
        // Fikri sil
        batch.deleteDocument(ideaRef)
        
        // Kategori istatistiklerini güncelle
        let categoryRef = db.collection("categories").document(idea.category)
        batch.updateData(["ideaCount": FieldValue.increment(Int64(-1))], forDocument: categoryRef)
        
        // Tüm beğenileri temizle (alt koleksiyonu sil)
        db.collection(ideasCollection).document(id).collection(likesCollection)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Beğeniler alınırken hata: \(error.localizedDescription)")
                    return
                }
                
                let likeBatch = self.db.batch()
                snapshot?.documents.forEach { doc in
                    likeBatch.deleteDocument(doc.reference)
                }
                
                likeBatch.commit { error in
                    if let error = error {
                        print("Beğeniler silinirken hata: \(error.localizedDescription)")
                    }
                }
            }
        
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Fikir silinirken hata oluştu: \(error.localizedDescription)"
            }
            
            // Son bakılanlar listesinden de sil
            self.recentlyViewedIdeas.removeAll { $0.id == id }
            self.saveRecentlyViewedIdeas()
        }
    }
    
    // Kullanıcının fikri beğenip beğenmediğini kontrol et
    func isIdeaLikedByUser(_ ideaId: String) -> Bool {
        return userLikedIdeas.contains(ideaId)
    }
    
    // Fikir beğenme
    func likeIdea(_ idea: Idea) {
        guard let ideaId = idea.id, let userId = Auth.auth().currentUser?.uid else {
            print("Beğeni için geçersiz fikir ID'si veya kullanıcı girişi yok")
            return
        }
        
        print("Beğeni işlemi başlatıldı, fikir ID: \(ideaId)")
        
        // Kullanıcı zaten beğendiyse, beğeniyi kaldır
        if isIdeaLikedByUser(ideaId) {
            print("Kullanıcı fikri zaten beğenmiş, beğeni kaldırılıyor...")
            unlikeIdea(idea)
            return
        }
        
        // Firestore için referanslar
        let ideaRef = db.collection(ideasCollection).document(ideaId)
        let userLikeRef = db.collection(usersCollection).document(userId).collection(likesCollection).document(ideaId)
        let ideaLikeRef = db.collection(ideasCollection).document(ideaId).collection(likesCollection).document(userId)
        
        // Batch işlemi oluştur
        let batch = db.batch()
        
        // Fikirin beğeni sayısını artır
        batch.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: ideaRef)
        
        // Kullanıcının beğeniler listesine ekle
        batch.setData([
            "timestamp": FieldValue.serverTimestamp(),
            "ideaTitle": idea.title
        ], forDocument: userLikeRef)
        
        // Fikrin beğenenleri listesine kullanıcıyı ekle
        batch.setData([
            "timestamp": FieldValue.serverTimestamp(),
            "userName": Auth.auth().currentUser?.displayName ?? "Anonim"
        ], forDocument: ideaLikeRef)
        
        // Batch işlemini çalıştır
        batch.commit { [weak self] error in
            if let error = error {
                print("Fikir beğenilirken hata oluştu: \(error.localizedDescription)")
                self?.errorMessage = "Fikir beğenilirken hata oluştu: \(error.localizedDescription)"
            } else {
                print("Fikir başarıyla beğenildi: \(ideaId)")
                // Yerel listede güncelle (UI anında güncellensin diye)
                self?.userLikedIdeas.insert(ideaId)
                
                // Bildirim gönder
                self?.sendLikeNotification(idea)
            }
        }
    }
    
    // Fikir beğenisini kaldır
    func unlikeIdea(_ idea: Idea) {
        guard let ideaId = idea.id, let userId = Auth.auth().currentUser?.uid else {
            print("Beğeni kaldırma için geçersiz fikir ID'si veya kullanıcı girişi yok")
            errorMessage = "Geçersiz fikir ID'si veya kullanıcı girişi yok"
            return
        }
        
        print("Beğeni kaldırma işlemi başlatıldı, fikir ID: \(ideaId)")
        
        // Firestore için referanslar
        let ideaRef = db.collection(ideasCollection).document(ideaId)
        let userLikeRef = db.collection(usersCollection).document(userId).collection(likesCollection).document(ideaId)
        let ideaLikeRef = db.collection(ideasCollection).document(ideaId).collection(likesCollection).document(userId)
        
        // Batch işlemi oluştur
        let batch = db.batch()
        
        // Fikirin beğeni sayısını azalt
        batch.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: ideaRef)
        
        // Kullanıcının beğeniler listesinden kaldır
        batch.deleteDocument(userLikeRef)
        
        // Fikrin beğenenleri listesinden kullanıcıyı kaldır
        batch.deleteDocument(ideaLikeRef)
        
        // Batch işlemini çalıştır
        batch.commit { [weak self] error in
            if let error = error {
                print("Beğeni kaldırılırken hata oluştu: \(error.localizedDescription)")
                self?.errorMessage = "Beğeni kaldırılırken hata oluştu: \(error.localizedDescription)"
            } else {
                print("Beğeni başarıyla kaldırıldı: \(ideaId)")
                // Yerel listede güncelle (UI anında güncellensin diye)
                self?.userLikedIdeas.remove(ideaId)
                
                // Firestore'dan güncel fikir bilgisini almak için fikiri yeniden getiriyoruz
                self?.refreshIdeaData(ideaId)
            }
        }
    }
    
    // Fikir verilerini yenile
    private func refreshIdeaData(_ ideaId: String) {
        db.collection(ideasCollection).document(ideaId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                // Belirli bir fikiri güncelle
                if let index = self?.ideas.firstIndex(where: { $0.id == ideaId }) {
                    if let data = document.data() {
                        let likeCount = data["likeCount"] as? Int ?? 0
                        // Sadece beğeni sayısını güncelle
                        self?.ideas[index].likeCount = likeCount
                        
                        print("Fikir verileri güncellendi, yeni beğeni sayısı: \(likeCount)")
                    }
                }
            } else if let error = error {
                print("Fikir verileri yenilenirken hata: \(error.localizedDescription)")
            }
        }
    }
    
    // Beğeni bildirimi gönder
    private func sendLikeNotification(_ idea: Idea) {
        guard let ideaId = idea.id,
              let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != idea.authorId else {
            return // Kendi fikrine beğeni bildirimi göndermeyelim
        }
        
        print("DEBUG - LIKE NOTIFICATION - Kullanıcı ID: \(currentUserId), Fikir ID: \(ideaId)")
        
        // Firestore'dan kullanıcı adını al
        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Kullanıcı bilgileri alınırken hata: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("DEBUG - HATA: Kullanıcı belgesi bulunamadı veya boş")
                return
            }
            
            // Debug için Firestore'dan alınan tüm verileri göster
            print("DEBUG - LIKE NOTIFICATION")
            print("Firestore'dan alınan kullanıcı verileri: \(data)")
            
            // Kullanıcının tam adını veya kullanıcı adını al
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            
            print("DEBUG - firstName: '\(firstName)', lastName: '\(lastName)', username: '\(username)'")
            
            // Öncelik tam ad, yoksa kullanıcı adı
            let senderName = (!firstName.isEmpty && !lastName.isEmpty) ? "\(firstName) \(lastName)" : username
            
            print("DEBUG - Seçilen senderName: '\(senderName)'")
            
            // Adın boş olup olmadığını kontrol et
            if senderName.isEmpty {
                print("DEBUG - HATA: Kullanıcı adı boş, varsayılan 'Bir kullanıcı' kullanılacak")
            }
            
            // Bildirim verileri oluştur
            let notificationData: [String: Any] = [
                "type": "like",
                "senderId": currentUserId,
                "senderName": senderName.isEmpty ? "Bir kullanıcı" : senderName,
                "receiverId": idea.authorId,
                "ideaId": ideaId,
                "ideaTitle": idea.title,
                "message": "\(senderName.isEmpty ? "Bir kullanıcı" : senderName) fikrinizi beğendi: \(idea.title)",
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false
            ]
            
            print("DEBUG - Oluşturulan bildirim verisi: \(notificationData)")
            
            // Bildirim ekle
            self.db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                    print("Bildirim gönderilirken hata: \(error.localizedDescription)")
                } else {
                    print("DEBUG - Beğeni bildirimi başarıyla eklendi")
                }
            }
        }
    }
    
    // Kategoriye göre fikirleri filtreleme
    func filterIdeasByCategory(_ category: Category?) {
        selectedCategory = category
        // Yeni kategori filtresiyle fikirleri yeniden getir
        if let listener = ideasListener {
            listener()
        }
        subscribeToIdeas()
    }
    
    // Popüler fikirleri gerçek zamanlı olarak getirme
    func getPopularIdeas() -> [Idea] {
        // Öncelikle mevcut fikirleri beğeni sayısına göre sıralayalım
        var sortedIdeas = ideas.sorted { $0.likeCount > $1.likeCount }
        
        // Son 24 saat içinde olan fikirleri filtrele
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        sortedIdeas = sortedIdeas.filter { $0.createdAt >= yesterday || $0.updatedAt >= yesterday }
        
        // Eğer cache'lenmiş fikirler varsa ve yükleme durumunda değilsek, hemen görüntülemek için bunları döndürelim
        if !sortedIdeas.isEmpty && !isLoading {
            // Anlık olarak bugünün en popüler fikirlerini Firebase'den de yenileyelim (arka planda)
            refreshTodayPopularIdeas()
            return sortedIdeas
        }
        
        // Cache boşsa veya yükleme durumundaysak, Firebase'den fresh veri bekleyin
        return sortedIdeas
    }
    
    // Bugünün popüler fikirlerini arka planda güncelle
    func refreshTodayPopularIdeas() {
        print("Bugünün popüler fikirleri güncel verilerle yenileniyor...")
        
        // Son 24 saat içindeki tarih
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayTimestamp = Timestamp(date: yesterday)
        
        // Son 24 saat içindeki en çok beğeni alan fikirleri getir (maksimum 10 tane)
        db.collection(ideasCollection)
            .whereField("updatedAt", isGreaterThanOrEqualTo: yesterdayTimestamp)
            .order(by: "updatedAt", descending: true)
            .order(by: "likeCount", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Bugünün popüler fikirleri yüklenirken hata: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Bugünün popüler fikirleri için veri bulunamadı")
                    return
                }
                
                // Elde edilen belgeleri Idea nesnelerine dönüştür
                let freshPopularIdeas = documents.compactMap { document -> Idea? in
                    let data = document.data()
                    
                    // Tarihleri dönüştür
                    let createdTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    let updatedTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
                    let viewedTimestamp = data["viewedAt"] as? Timestamp
                    
                    let idea = Idea(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "",
                        category: data["category"] as? String ?? "",
                        createdAt: createdTimestamp.dateValue(),
                        updatedAt: updatedTimestamp.dateValue(),
                        likeCount: data["likeCount"] as? Int ?? 0,
                        commentCount: data["commentCount"] as? Int ?? 0,
                        viewCount: data["viewCount"] as? Int ?? 0,
                        viewedAt: viewedTimestamp?.dateValue()
                    )
                    
                    return idea
                }
                
                // Mevcut listedeki fikirleri güncelle
                DispatchQueue.main.async {
                    print("Bugünün popüler fikirleri güncellendi: \(freshPopularIdeas.count) fikir")
                    
                    // İdeas listesindeki fikirleri güncelle
                    for freshIdea in freshPopularIdeas {
                        if let index = self.ideas.firstIndex(where: { $0.id == freshIdea.id }) {
                            // Varolan fikiri güncelle
                            self.ideas[index] = freshIdea
                        } else {
                            // Yeni fikir, listeye ekle
                            self.ideas.append(freshIdea)
                        }
                    }
                }
            }
    }
    
    // Ana sayfadaki popüler fikirleri yenilemek için refreshPopularIdeas metodunu güncelliyoruz
    func refreshPopularIdeas() {
        refreshTodayPopularIdeas()
    }
    
    // Yeni fikirleri getirme
    func getRecentIdeas() -> [Idea] {
        return ideas.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Filtrelenmiş fikirleri getirme
    func getFilteredIdeas() -> [Idea] {
        if let selectedCategory = selectedCategory {
            return ideas.filter { $0.category == selectedCategory.name }
        } else {
            return ideas
        }
    }
    
    // Test verisi yükleme (geliştirme aşamasında kullanılabilir)
    func loadExampleData() {
        let exampleIdeas = Idea.examples
        
        let batch = db.batch()
        
        for idea in exampleIdeas {
            let docRef = db.collection(ideasCollection).document(idea.id ?? UUID().uuidString)
            
            // Dictionary olarak veriyi ekle
            let ideaData: [String: Any] = [
                "title": idea.title,
                "description": idea.description,
                "authorId": idea.authorId,
                "authorName": idea.authorName,
                "category": idea.category,
                "createdAt": Timestamp(date: idea.createdAt),
                "updatedAt": Timestamp(date: idea.updatedAt),
                "likeCount": idea.likeCount,
                "commentCount": idea.commentCount,
                "viewCount": 0 // Görüntülenme sayısı ekle
            ]
            
            batch.setData(ideaData, forDocument: docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                self?.errorMessage = "Örnek veriler yüklenirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Arama İşlevleri
    
    // Arama metnine göre fikirleri filtreleme
    func searchIdeas() {
        guard !searchText.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        lastSearchQuery = searchText
        
        // Firestore sorgusu için arama metni hazırlama
        let searchTerms = searchText.lowercased().split(separator: " ").map(String.init)
        
        // Yerel arama (tüm fikirler zaten indirilmiş durumda)
        let filteredIdeas = ideas.filter { idea in
            let titleMatches = searchTerms.contains { term in
                idea.title.lowercased().contains(term)
            }
            
            let descriptionMatches = searchTerms.contains { term in
                idea.description.lowercased().contains(term)
            }
            
            let categoryMatches = searchTerms.contains { term in
                idea.category.lowercased().contains(term)
            }
            
            let authorMatches = searchTerms.contains { term in
                idea.authorName.lowercased().contains(term)
            }
            
            return titleMatches || descriptionMatches || categoryMatches || authorMatches
        }
        
        searchResults = filteredIdeas
        isSearching = false
    }
    
    // Arama sonuçlarını temizleme
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
    
    // Gelişmiş Firestore araması - Büyük veri setlerinde daha verimli
    func advancedSearchIdeas() {
        guard !searchText.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        lastSearchQuery = searchText
        
        // Arama terimlerini hazırlama
        let searchTerm = searchText.lowercased()
        
        // Firestore sorgusu oluştur
        // Not: Firestore tam metin araması desteklemez, bu yüzden temel filtreleri kullanacağız
        let query = db.collection(ideasCollection)
            .whereField("title", isGreaterThanOrEqualTo: searchTerm)
            .whereField("title", isLessThan: searchTerm + "z")
            .limit(to: 20)
        
        query.getDocuments { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            guard let self = self else { return }
            
            if let error = error {
                print("Arama yapılırken hata: \(error.localizedDescription)")
                self.isSearching = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.searchResults = []
                self.isSearching = false
                return
            }
            
            // Belgeleri Idea objelerine dönüştür
            let results = documents.compactMap { document -> Idea? in
                let data = document.data()
                
                // Tarihleri dönüştür
                let createdTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                let updatedTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
                let viewedTimestamp = data["viewedAt"] as? Timestamp
                
                return Idea(
                    id: document.documentID,
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    authorId: data["authorId"] as? String ?? "",
                    authorName: data["authorName"] as? String ?? "",
                    category: data["category"] as? String ?? "",
                    createdAt: createdTimestamp.dateValue(),
                    updatedAt: updatedTimestamp.dateValue(),
                    likeCount: data["likeCount"] as? Int ?? 0,
                    commentCount: data["commentCount"] as? Int ?? 0,
                    viewCount: data["viewCount"] as? Int ?? 0,
                    viewedAt: viewedTimestamp?.dateValue()
                )
            }
            
            self.searchResults = results
            self.isSearching = false
        }
    }
    
    // Takip edilen kullanıcıların ID'lerini getir
    private func fetchFollowingUserIds() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Kullanıcının takip ettiklerini yükle
        db.collection(usersCollection).document(userId)
            .collection("following")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Takip edilen kullanıcılar yüklenirken hata: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.followingUserIds = documents.compactMap { $0.documentID }
                    print("Takip edilen kullanıcılar yüklendi: \(self.followingUserIds.count)")
                }
            }
    }
    
    // Akış tipine göre fikirleri getir
    func getIdeasForCurrentFeed() -> [Idea] {
        switch feedType {
        case .forYou:
            // Tüm fikirler (kategoriye göre filtrelenmiş olabilir)
            return getFilteredIdeas()
        case .following:
            // Takip edilenlerin fikirleri
            return getFollowingUsersIdeas()
        }
    }
    
    // Takip edilen kullanıcıların fikirlerini getir
    func getFollowingUsersIdeas() -> [Idea] {
        if followingUserIds.isEmpty {
            return []
        }
        
        // Önce kategoriye göre filtrele
        var filteredIdeas = ideas
        if let selectedCategory = selectedCategory {
            filteredIdeas = filteredIdeas.filter { $0.category == selectedCategory.name }
        }
        
        // Sonra takip edilenlere göre filtrele
        let followingIdeas = filteredIdeas.filter { idea in
            return followingUserIds.contains(idea.authorId)
        }
        
        // Tarihe göre sırala (en yeni üstte)
        return followingIdeas.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Akış tipini değiştir
    func switchFeedType(to type: FeedType) {
        feedType = type
    }
    
    // MARK: - Fetch Methods
    
    // Fetch a specific idea by ID
    func fetchIdeaById(_ ideaId: String, completion: @escaping (Idea?) -> Void) {
        print("DEBUG - Fikir getiriliyor, ID: \(ideaId)")
        
        Firestore.firestore().collection("ideas").document(ideaId).getDocument { snapshot, error in
            if let error = error {
                print("DEBUG - Fikir alınırken hata: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                print("DEBUG - Fikir bulunamadı, ID: \(ideaId)")
                completion(nil)
                return
            }
            
            let idea = self.parseIdeaFromSnapshot(document: snapshot)
            completion(idea)
        }
    }
    
    // Helper method to parse an Idea from a Firestore document snapshot
    private func parseIdeaFromSnapshot(document: DocumentSnapshot) -> Idea? {
        let data = document.data() ?? [:]
        
        // Tarihleri dönüştür
        let createdTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let updatedTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
        let viewedTimestamp = data["viewedAt"] as? Timestamp
        
        return Idea(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            authorId: data["authorId"] as? String ?? "",
            authorName: data["authorName"] as? String ?? "",
            category: data["category"] as? String ?? "",
            createdAt: createdTimestamp.dateValue(),
            updatedAt: updatedTimestamp.dateValue(),
            likeCount: data["likeCount"] as? Int ?? 0,
            commentCount: data["commentCount"] as? Int ?? 0,
            viewCount: data["viewCount"] as? Int ?? 0,
            viewedAt: viewedTimestamp?.dateValue()
        )
    }
} 