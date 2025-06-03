import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                Color.themeBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık
                        Text("Yeni Hesap Oluştur")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.themeTextPrimary)
                            .padding(.top)
                        
                        // Hata mesajı
                        if let error = authViewModel.registerError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.themeAccent)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Kayıt formu
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Kullanıcı Adı", 
                                placeholder: "Kullanıcı adınızı girin", 
                                text: $username,
                                icon: "person"
                            )
                            
                            CustomTextField(
                                title: "E-posta", 
                                placeholder: "E-posta adresinizi girin", 
                                text: $email,
                                icon: "envelope", 
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                title: "Ad", 
                                placeholder: "Adınızı girin", 
                                text: $firstName,
                                icon: "person.text.rectangle"
                            )
                            
                            CustomTextField(
                                title: "Soyad", 
                                placeholder: "Soyadınızı girin", 
                                text: $lastName,
                                icon: "person.text.rectangle"
                            )
                            
                            CustomTextField(
                                title: "Şifre", 
                                placeholder: "Şifrenizi girin", 
                                isSecure: true, 
                                text: $password,
                                icon: "lock"
                            )
                            
                            CustomTextField(
                                title: "Şifre Tekrar", 
                                placeholder: "Şifrenizi tekrar girin", 
                                isSecure: true, 
                                text: $confirmPassword,
                                icon: "lock.shield"
                            )
                            
                            Button(action: {
                                withAnimation {
                                    isLoading = true
                                    authViewModel.register(
                                        username: username,
                                        email: email,
                                        firstName: firstName,
                                        lastName: lastName,
                                        password: password,
                                        confirmPassword: confirmPassword
                                    )
                                    
                                    // Firebase entegrasyonu nedeniyle, register işlemi asenkron
                                    // olduğundan isLoading'i otomatik kapatamayız.
                                    // Gerçek uygulamada bu durum completion handler ile yönetilmelidir.
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isLoading = false
                                        if authViewModel.isAuthenticated {
                                            dismiss()
                                        }
                                    }
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Kayıt Ol")
                                }
                            }
                            .primaryButtonStyle()
                            .disabled(isFormInvalid || isLoading)
                        }
                        .padding(.horizontal)
                        
                        // Giriş yapma bağlantısı
                        Button("Zaten hesabınız var mı? Giriş Yap") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.themePrimary)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                }
            }
        }
    }
    
    // Form doğrulama
    private var isFormInvalid: Bool {
        return username.isEmpty || 
               email.isEmpty || 
               firstName.isEmpty || 
               lastName.isEmpty || 
               password.isEmpty || 
               confirmPassword.isEmpty ||
               password != confirmPassword
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(authViewModel: AuthViewModel())
    }
} 