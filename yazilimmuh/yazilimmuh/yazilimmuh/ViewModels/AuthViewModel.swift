import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Auth durumu değişikliklerini bildirmek için bildirim adı
extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}

class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var loginError: String?
    @Published var registerError: String?
    @Published var resetPasswordMessage: String?
    @Published var profileUpdateMessage: String?
    @Published var isUpdatingProfile = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Auth durumu değişikliklerini dinle
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.user = user
                self.isAuthenticated = user != nil
                
                // Oturum açılmışsa kullanıcı bilgilerini yükle
                if let user = user {
                    self.fetchUserData(uid: user.uid)
                } else {
                    self.currentUser = nil
                }
                
                // Auth durumu değişikliğini bildir
                NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
            }
        }
    }
    
    // Firestore'dan kullanıcı bilgilerini getir
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                self?.isAuthenticated = false
                return
            }
            
            let data = document.data() ?? [:]
            
            // Tarihleri dönüştür
            let joinTimestamp = data["joinDate"] as? Timestamp ?? Timestamp(date: Date())
            
            let userData = User(
                id: document.documentID,
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
            
            self.currentUser = userData
            self.isAuthenticated = true
        }
    }
    
    // Giriş işlemi
    func login(email: String, password: String) {
        if email.isEmpty || password.isEmpty {
            self.loginError = "E-posta ve şifre alanları boş bırakılamaz."
            return
        }
        
        // Geliştirme sırasında test hesabı ile giriş yapabilmek için
        if email == "test" && password == "1" {
            self.currentUser = User.example
            self.isAuthenticated = true
            self.loginError = nil
            return
        }
        
        auth.signIn(withEmail: email, password: password) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.loginError = error.localizedDescription
                self.isAuthenticated = false
                return
            }
            
            if let uid = result?.user.uid {
                self.fetchUserData(uid: uid)
            }
        }
    }
    
    // Kayıt işlemi
    func register(username: String, email: String, firstName: String, lastName: String, password: String, confirmPassword: String) {
        if username.isEmpty || email.isEmpty || firstName.isEmpty || lastName.isEmpty || password.isEmpty {
            self.registerError = "Tüm alanlar doldurulmalıdır."
            return
        }
        
        if password != confirmPassword {
            self.registerError = "Şifreler eşleşmiyor."
            return
        }
        
        auth.createUser(withEmail: email, password: password) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.registerError = error.localizedDescription
                return
            }
            
            if let user = result?.user {
                let uid = user.uid
                
                // Kullanıcı displayName'ini ayarla
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = "\(firstName) \(lastName)" // Tam ad olarak ayarla
                
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("DisplayName güncellenirken hata: \(error.localizedDescription)")
                    } else {
                        print("DisplayName başarıyla güncellendi: \(firstName) \(lastName)")
                    }
                }
                
                // Yeni kullanıcı verisi
                let userData: [String: Any] = [
                    "username": username,
                    "email": email, 
                    "firstName": firstName,
                    "lastName": lastName,
                    "joinDate": Timestamp(date: Date()),
                    "recentlyViewedIdeas": [],
                    "followersCount": 0,
                    "followingCount": 0,
                    "bio": "",
                    "profileImageUrl": ""
                ]
                
                // Firestore'a kullanıcı bilgilerini kaydet
                self.db.collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        self.registerError = "Kullanıcı bilgileri kaydedilemedi: \(error.localizedDescription)"
                        return
                    }
                    
                    let newUser = User(
                        id: uid,
                        username: username,
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        joinDate: Date(),
                        recentlyViewedIdeas: [],
                        followersCount: 0,
                        followingCount: 0,
                        bio: "",
                        profileImageUrl: nil
                    )
                    
                    self.currentUser = newUser
                    self.isAuthenticated = true
                    self.registerError = nil
                }
            }
        }
    }
    
    // Çıkış işlemi
    func logout() {
        do {
            try auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            print("Çıkış yapılırken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // Şifre sıfırlama işlemi
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty else {
            self.resetPasswordMessage = "E-posta adresi boş olamaz."
            completion(false)
            return
        }
        
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.resetPasswordMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            self.resetPasswordMessage = "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi."
            completion(true)
        }
    }
    
    // Profil güncelleme işlemi
    func updateProfile(firstName: String, lastName: String, username: String, bio: String, profileImage: UIImage?, completion: @escaping (Bool) -> Void) {
        guard let userId = user?.uid, let currentUser = self.currentUser else {
            self.profileUpdateMessage = "Kullanıcı girişi yapılmamış"
            completion(false)
            return
        }
        
        self.isUpdatingProfile = true
        
        // Profil resmi varsa önce onu Base64'e dönüştür
        if let profileImage = profileImage {
            let imageBase64 = convertImageToBase64(image: profileImage)
            
            // Profil resmini ve diğer bilgileri güncelle
            self.updateUserData(userId: userId, firstName: firstName, lastName: lastName, username: username, bio: bio, profileImageBase64: imageBase64) { success in
                self.isUpdatingProfile = false
                completion(success)
            }
        } else {
            // Profil resmi yoksa sadece diğer bilgileri güncelle
            updateUserData(userId: userId, firstName: firstName, lastName: lastName, username: username, bio: bio, profileImageBase64: nil) { [weak self] success in
                guard let self = self else { return }
                self.isUpdatingProfile = false
                completion(success)
            }
        }
    }
    
    // Kullanıcı verilerini güncelleme (Firebase'e kaydetme)
    private func updateUserData(userId: String, firstName: String, lastName: String, username: String, bio: String, profileImageBase64: String?, completion: @escaping (Bool) -> Void) {
        // Kullanıcı verilerini oluştur
        var userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "username": username,
            "bio": bio
        ]
        
        // Profil resmi varsa Base64 olarak ekle
        if let profileImageBase64 = profileImageBase64 {
            // Doğrudan profileImageUrl alanına data:image/jpeg;base64, önekiyle birlikte kaydediyoruz
            userData["profileImageUrl"] = "data:image/jpeg;base64,\(profileImageBase64)"
        }
        
        // Firebase Authentication displayName güncelleme
        if let user = auth.currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            
            changeRequest.commitChanges { error in
                if let error = error {
                    print("DisplayName güncellenirken hata: \(error.localizedDescription)")
                } else {
                    print("DisplayName başarıyla güncellendi: \(firstName) \(lastName)")
                }
            }
        }
        
        // Firestore'daki kullanıcı belgesini güncelle
        db.collection("users").document(userId).updateData(userData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.profileUpdateMessage = "Profil bilgileri güncellenemedi: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            // Yerel verileri güncelle
            if var updatedUser = self.currentUser {
                updatedUser.firstName = firstName
                updatedUser.lastName = lastName
                updatedUser.username = username
                updatedUser.bio = bio
                
                if let profileImageBase64 = profileImageBase64 {
                    // Eski URL yerine, profile fotografını tam URL formatıyla saklıyoruz
                    updatedUser.profileImageUrl = "data:image/jpeg;base64,\(profileImageBase64)"
                }
                
                self.currentUser = updatedUser
            }
            
            self.profileUpdateMessage = "Profil bilgileri başarıyla güncellendi."
            completion(true)
        }
    }
    
    // Resmi Base64'e dönüştürme
    private func convertImageToBase64(image: UIImage) -> String {
        // Resmi küçült
        let targetSize = CGSize(width: 300, height: 300)
        let scaledImage = image.scaledToFill(targetSize: targetSize)
        
        // JPEG formatına düşük kalitede dönüştür
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.5) else {
            return ""
        }
        
        return imageData.base64EncodedString()
    }
}

// UIImage uzantısı
extension UIImage {
    func scaledToFill(targetSize: CGSize) -> UIImage {
        // Boyut belirleme
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = max(widthRatio, heightRatio)
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Resmi yeniden boyutlandır
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                x: (targetSize.width - scaledImageSize.width) / 2,
                y: (targetSize.height - scaledImageSize.height) / 2,
                width: scaledImageSize.width,
                height: scaledImageSize.height
            ))
        }
        
        return scaledImage
    }
} 