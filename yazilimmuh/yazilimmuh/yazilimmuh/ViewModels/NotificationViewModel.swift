import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class NotificationViewModel: ObservableObject {
    // MARK: - Notification Type Enum
    enum NotificationType: String, CaseIterable, Codable {
        case like = "like"
        case comment = "comment"
        case newIdea = "newIdea"
        case mention = "mention"
        case system = "system"
        
        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .comment: return "bubble.left.fill"
            case .newIdea: return "lightbulb.fill"
            case .mention: return "at"
            case .system: return "bell.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .like: return .red
            case .comment: return .blue
            case .newIdea: return .orange
            case .mention: return .green
            case .system: return .purple
            }
        }
        
        var title: String {
            switch self {
            case .like: return "Beğeni"
            case .comment: return "Yorum"
            case .newIdea: return "Yeni Fikir"
            case .mention: return "Etiketleme"
            case .system: return "Sistem"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case rawValue
        }
    }
    
    // MARK: - Notification Model
    struct AppNotification: Identifiable, Codable {
        let id: UUID
        let title: String
        let message: String
        let type: NotificationType
        var isRead: Bool
        let createdAt: Date
        let relatedContentId: String?
        let relatedContentType: String?
        
        init(id: UUID = UUID(), 
             title: String, 
             message: String, 
             type: NotificationType, 
             isRead: Bool = false, 
             createdAt: Date = Date(),
             relatedContentId: String? = nil,
             relatedContentType: String? = nil) {
            self.id = id
            self.title = title
            self.message = message
            self.type = type
            self.isRead = isRead
            self.createdAt = createdAt
            self.relatedContentId = relatedContentId
            self.relatedContentType = relatedContentType
        }
        
        var timeAgo: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: createdAt, relativeTo: Date())
        }
        
        enum CodingKeys: String, CodingKey {
            case id, title, message, type, isRead, createdAt, relatedContentId, relatedContentType
        }
    }
    
    // MARK: - Published Properties
    @Published var notifications: [AppNotification] = []
    @Published var hasPermission: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published private(set) var hasActiveListener: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "savedNotifications"
    private var notificationsListener: FirebaseFirestore.ListenerRegistration? = nil
    private var isListenerBeingSetUp = false
    
    // MARK: - Initialization
    init() {
        checkPermissionStatus()
        loadSavedNotifications()
        
        // Firebase Authentication dinle
        NotificationCenter.default.addObserver(self, selector: #selector(authStateChanged), name: .AuthStateDidChange, object: nil)
        
        // Artık otomatik yüklemiyoruz - kullanıcı bildirimler sayfasına girdiğinde yüklenecek
        // if Auth.auth().currentUser != nil {
        //    fetchNotifications()
        // }
    }
    
    deinit {
        // Listener'ları temizle
        removeNotificationsListener()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func authStateChanged() {
        if Auth.auth().currentUser != nil {
            // User logged in - we dont fetch here, will fetch when notifications view appears
            // fetchNotifications()
            #if DEBUG
            print("DEBUG - NotificationViewModel: Kullanıcı giriş yaptı, bildirimler view açıldığında yüklenecek")
            #endif
        } else {
            // Kullanıcı çıkış yaptı, bildirimleri temizle
            notifications = []
            removeNotificationsListener()
        }
    }
    
    // MARK: - Permission Methods
    func checkPermissionStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        #if !targetEnvironment(simulator)
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }
    
    // MARK: - Fetch Methods
    func fetchNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("DEBUG - NotificationViewModel: Kullanıcı giriş yapmamış, bildirimler yüklenemedi")
            #endif
            return
        }
        
        // Önceki dinleyicileri tamamen temizle
        if notificationsListener != nil {
            notificationsListener?.remove()
            notificationsListener = nil
        }
        
        // Dinleyici kullanmıyoruz artık
        hasActiveListener = false
        
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        print("DEBUG - NotificationViewModel: Bildirimler yükleniyor (tek seferlik sorgu)...")
        #endif
        
        // Tek seferlik sorgu yap - dinleyici YOK
        Firestore.firestore().collection("notifications")
            .whereField("receiverId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // UI güncellemelerini ana thread'de yapmalıyız
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        #if DEBUG
                        print("DEBUG - NotificationViewModel: Bildirimler yüklenirken hata: \(error.localizedDescription)")
                        #endif
                        self.errorMessage = "Bildirimler yüklenirken bir hata oluştu"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        #if DEBUG
                        print("DEBUG - NotificationViewModel: Bildirim belgesi bulunamadı")
                        #endif
                        self.notifications = []
                        return
                    }
                    
                    #if DEBUG
                    print("DEBUG - NotificationViewModel: \(documents.count) bildirim bulundu")
                    #endif
                    
                    // Firebase'den gelen bildirimleri dönüştür
                    var firebaseNotifications: [AppNotification] = []
                    
                    for document in documents {
                        let data = document.data()
                        
                        // Gerekli alanları çıkar
                        guard let type = data["type"] as? String,
                              let message = data["message"] as? String,
                              let isRead = data["isRead"] as? Bool else {
                            #if DEBUG
                            print("DEBUG - NotificationViewModel: Bildirim verisi eksik veya hatalı")
                            #endif
                            continue
                        }
                        
                        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                        let senderId = data["senderId"] as? String
                        let senderName = data["senderName"] as? String ?? "Bir kullanıcı"
                        let ideaId = data["ideaId"] as? String
                        let ideaTitle = data["ideaTitle"] as? String
                        
                        // Bildirim tipi enum'a dönüştür
                        let notificationType: NotificationType
                        switch type {
                        case "like": notificationType = .like
                        case "comment": notificationType = .comment
                        case "follow": notificationType = .mention  // follow tipi şimdilik mention olarak işaretleniyor
                        case "newIdea": notificationType = .newIdea
                        case "system": notificationType = .system
                        default: notificationType = .system
                        }
                        
                        // Başlık oluştur
                        var title = ""
                        switch notificationType {
                        case .like: title = "Fikriniz beğenildi"
                        case .comment: title = "Fikrinize yorum yapıldı"
                        case .newIdea: title = "Yeni bir fikir eklendi"
                        case .mention: title = "Takip edildiniz"
                        case .system: title = "Sistem bildirimi"
                        }
                        
                        // AppNotification nesnesini oluştur
                        let notification = AppNotification(
                            id: UUID(),
                            title: title,
                            message: message,
                            type: notificationType,
                            isRead: isRead,
                            createdAt: timestamp.dateValue(),
                            relatedContentId: ideaId,
                            relatedContentType: ideaId != nil ? "idea" : nil
                        )
                        
                        firebaseNotifications.append(notification)
                    }
                    
                    // Bildirimleri güncelle
                    self.notifications = firebaseNotifications
                    
                    #if DEBUG
                    print("DEBUG - NotificationViewModel: \(self.notifications.count) bildirim yüklendi")
                    #endif
                    
                    // Yerel olarak kaydet
                    self.saveNotifications()
                }
            }
    }
    
    // Remove existing listener - sadece temizlik için
    func removeNotificationsListener() {
        if notificationsListener != nil {
            #if DEBUG
            print("DEBUG - NotificationViewModel: Bildirim dinleyicisi kaldırılıyor")
            #endif
            notificationsListener?.remove()
            notificationsListener = nil
            hasActiveListener = false
        }
    }
    
    // MARK: - Local Storage Methods
    private func loadSavedNotifications() {
        if let data = userDefaults.data(forKey: notificationsKey),
           let decodedNotifications = try? JSONDecoder().decode([AppNotification].self, from: data) {
            self.notifications = decodedNotifications.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: notificationsKey)
        }
    }
    
    // MARK: - Notification State Management
    func markAsRead(_ notification: AppNotification) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Skip if already read
        if notification.isRead {
            #if DEBUG
            print("DEBUG - Bildirim zaten okunmuş, işlem atlandı")
            #endif
            return
        }
        
        // Yerel bildirimi güncelle
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
        
        // Ek debug bilgisi
        #if DEBUG
        print("DEBUG - Firebase'de bildirim güncelleniyor: \(notification.message)")
        #endif
        
        // Mesajı ve alıcı ID'sini kullanarak sorgu
        let notificationsRef = Firestore.firestore().collection("notifications")
        
        notificationsRef
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("message", isEqualTo: notification.message)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    #if DEBUG
                    print("DEBUG - Bildirim güncellenirken hata: \(error.localizedDescription)")
                    #endif
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    #if DEBUG
                    print("DEBUG - Güncellenmek üzere bildirim bulunamadı. Tüm bildirimleri arayacağım")
                    #endif
                    
                    // İkinci bir deneme: sadece isRead filtresini kaldırarak
                    notificationsRef
                        .whereField("receiverId", isEqualTo: currentUserId)
                        .whereField("message", isEqualTo: notification.message)
                        .getDocuments { snapshot, error in
                            if let error = error {
                                #if DEBUG
                                print("DEBUG - İkinci sorgu hatası: \(error.localizedDescription)")
                                #endif
                                return
                            }
                            
                            guard let documents = snapshot?.documents, !documents.isEmpty else {
                                #if DEBUG
                                print("DEBUG - İkinci sorguda da bildirim bulunamadı")
                                #endif
                                return
                            }
                            
                            #if DEBUG
                            print("DEBUG - İkinci sorguda \(documents.count) bildirim bulundu")
                            #endif
                            
                            // Bulunan tüm bildirimleri güncelle
                            for document in documents {
                                self.updateFirestoreNotification(documentId: document.documentID)
                            }
                        }
                    return
                }
                
                #if DEBUG
                print("DEBUG - İlk sorguda \(documents.count) bildirim bulundu")
                #endif
                
                // Bulunan tüm bildirimleri güncelle
                for document in documents {
                    self.updateFirestoreNotification(documentId: document.documentID)
                }
            }
    }
    
    // Firestore bildirimini güncelleme yardımcı fonksiyonu
    private func updateFirestoreNotification(documentId: String) {
        let docRef = Firestore.firestore().collection("notifications").document(documentId)
        
        #if DEBUG
        print("DEBUG - Bildirim güncelleniyor: \(documentId)")
        #endif
        
        // Bildirim belgesinin mevcut durumunu kontrol et
        docRef.getDocument { snapshot, error in
            if let error = error {
                #if DEBUG
                print("DEBUG - Bildirim belgesi kontrol edilirken hata: \(error.localizedDescription)")
                #endif
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                #if DEBUG
                print("DEBUG - Bildirim belgesi bulunamadı: \(documentId)")
                #endif
                return
            }
            
            let data = snapshot.data() ?? [:]
            let currentReadStatus = data["isRead"] as? Bool ?? false
            
            #if DEBUG
            print("DEBUG - Mevcut isRead değeri: \(currentReadStatus)")
            #endif
            
            // İşlem yap - değişiklikleri yaz
            docRef.updateData([
                "isRead": true,
                "readAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    #if DEBUG
                    print("DEBUG - Bildirim okundu olarak işaretlenemedi: \(error.localizedDescription)")
                    #endif
                } else {
                    #if DEBUG
                    print("DEBUG - Bildirim başarıyla okundu olarak işaretlendi: \(documentId)")
                    #endif
                }
            }
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveNotifications()
    }
    
    func deleteNotification(_ notification: AppNotification) {
        // Yerel olarak kaldır
        notifications.removeAll(where: { $0.id == notification.id })
        saveNotifications()
        
        // Firebase'den kaldır
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Mesaj içeriğini kullanarak bildirimi bul ve sil
        Firestore.firestore().collection("notifications")
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("message", isEqualTo: notification.message)
            .getDocuments { snapshot, error in
                if let error = error {
                    #if DEBUG
                    print("DEBUG - Bildirim silinirken hata: \(error.localizedDescription)")
                    #endif
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    #if DEBUG
                    print("DEBUG - Silinecek bildirim bulunamadı")
                    #endif
                    return
                }
                
                // Bulunan bildirimleri sil
                for document in documents {
                    Firestore.firestore().collection("notifications").document(document.documentID).delete { error in
                        if let error = error {
                            #if DEBUG
                            print("DEBUG - Bildirim Firebase'den silinirken hata: \(error.localizedDescription)")
                            #endif
                        } else {
                            #if DEBUG
                            print("DEBUG - Bildirim Firebase'den başarıyla silindi: \(document.documentID)")
                            #endif
                        }
                    }
                }
            }
    }
    
    func clearAllNotifications() {
        // Yerel olarak tüm bildirimleri kaldır
        notifications.removeAll()
        saveNotifications()
        
        // Firebase'den kullanıcının tüm bildirimlerini kaldır
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("notifications")
            .whereField("receiverId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    #if DEBUG
                    print("DEBUG - Tüm bildirimler silinirken hata: \(error.localizedDescription)")
                    #endif
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    #if DEBUG
                    print("DEBUG - Silinecek bildirim bulunamadı")
                    #endif
                    return
                }
                
                let batch = Firestore.firestore().batch()
                
                // Toplu silme işlemi için batch kullan
                for document in documents {
                    let docRef = Firestore.firestore().collection("notifications").document(document.documentID)
                    batch.deleteDocument(docRef)
                }
                
                // Batch işlemini uygula
                batch.commit { error in
                    if let error = error {
                        #if DEBUG
                        print("DEBUG - Tüm bildirimler Firebase'den silinirken hata: \(error.localizedDescription)")
                        #endif
                    } else {
                        #if DEBUG
                        print("DEBUG - \(documents.count) bildirim Firebase'den başarıyla silindi")
                        #endif
                    }
                }
            }
    }
    
    // MARK: - Create Notification
    func createNotification(title: String, message: String, type: NotificationType, relatedContentId: String? = nil, relatedContentType: String? = nil, showLocal: Bool = false) {
        let notification = AppNotification(
            title: title,
            message: message,
            type: type,
            relatedContentId: relatedContentId,
            relatedContentType: relatedContentType
        )
        
        notifications.insert(notification, at: 0)
        saveNotifications()
        
        // Yerel bildirim göster
        if showLocal && hasPermission {
            showLocalNotification(title: title, body: message, type: type)
        }
    }
    
    // MARK: - Local Notification
    private func showLocalNotification(title: String, body: String, type: NotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Kategori ve özel aksiyonlar eklenebilir
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                #if DEBUG
                print("Bildirim gösterilirken hata oluştu: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    #if DEBUG
    // MARK: - Test Functions
    func addTestNotification() {
        let types: [NotificationType] = [.like, .comment, .newIdea, .mention, .system]
        let randomType = types.randomElement() ?? .system
        
        var title = ""
        var message = ""
        
        switch randomType {
        case .like:
            title = "Fikriniz beğenildi"
            message = "Ahmet Yılmaz, 'Akıllı Sulama Sistemi' fikrinizi beğendi"
        case .comment:
            title = "Fikrinize yorum yapıldı"
            message = "Ayşe Kaya, 'Yapay zeka destekli Not Uygulaması' fikrinize yorum yaptı: 'Harika bir fikir!'"
        case .newIdea:
            title = "Yeni bir fikir eklendi"
            message = "Kategorinizde yeni bir fikir paylaşıldı: 'Sesli Kitap Uygulaması'"
        case .mention:
            title = "Bir yorumda etiketlendiniz"
            message = "Mehmet Demir sizi bir yorumda etiketledi: '@test bu konuda ne düşünüyorsun?'"
        case .system:
            title = "Sistem bildirimi"
            message = "Uygulamamız güncellendi! Yeni özellikleri keşfedin."
        }
        
        let contentTypes = ["idea", "comment", "user", "category"]
        let relatedContentType = Bool.random() ? contentTypes.randomElement() : nil
        let relatedContentId = relatedContentType != nil ? UUID().uuidString : nil
        
        createNotification(
            title: title,
            message: message,
            type: randomType,
            relatedContentId: relatedContentId,
            relatedContentType: relatedContentType
        )
    }
    #endif
}

// MARK: - Extensions
extension NotificationViewModel.NotificationType: Identifiable {
    var id: String { rawValue }
}

// MARK: - Preview Helpers
extension NotificationViewModel {
    static func previewModel() -> NotificationViewModel {
        let model = NotificationViewModel()
        model.createNotification(
            title: "Fikriniz beğenildi",
            message: "Ahmet Yılmaz, 'Akıllı Ev Sistemleri' fikrinizi beğendi",
            type: .like,
            relatedContentId: "idea-123",
            relatedContentType: "idea"
        )
        model.createNotification(
            title: "Bir yorumda etiketlendiniz",
            message: "Mehmet Demir sizi bir yorumda etiketledi: '@test bu konuda ne düşünüyorsun?'",
            type: .mention,
            relatedContentId: "comment-456",
            relatedContentType: "comment"
        )
        return model
    }
}

// MARK: - Utility Properties
extension NotificationViewModel {
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
} 