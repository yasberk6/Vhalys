import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var loginError: String?
    @Published var registerError: String?
    
    // Giriş işlemi
    func login(email: String, password: String) {
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için test verileri kullanıyoruz
        
        if email.isEmpty || password.isEmpty {
            self.loginError = "E-posta ve şifre alanları boş bırakılamaz."
            return
        }
        
        // Test kullanıcısı ile giriş yapalım
        if email == "test" && password == "1" {
            self.currentUser = User.example
            self.isAuthenticated = true
            self.loginError = nil
        } else {
            self.loginError = "Geçersiz e-posta veya şifre."
            self.isAuthenticated = false
        }
    }
    
    // Kayıt işlemi
    func register(username: String, email: String, firstName: String, lastName: String, password: String, confirmPassword: String) {
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için kontroller yapıyoruz
        
        if username.isEmpty || email.isEmpty || firstName.isEmpty || lastName.isEmpty || password.isEmpty {
            self.registerError = "Tüm alanlar doldurulmalıdır."
            return
        }
        
        if password != confirmPassword {
            self.registerError = "Şifreler eşleşmiyor."
            return
        }
        
        // Test için başarılı kayıt işlemi
        // Gerçek implementasyonda backend API'si ile entegre edilecek
        self.currentUser = User(
            id: UUID().uuidString,
            username: username,
            email: email,
            firstName: firstName,
            lastName: lastName,
            joinDate: Date()
        )
        self.isAuthenticated = true
        self.registerError = nil
    }
    
    // Çıkış işlemi
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
} 