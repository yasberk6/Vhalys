import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Başlık
                    Text("Yeni Hesap Oluştur")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Hata mesajı
                    if let error = viewModel.registerError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Kayıt formu
                    VStack(spacing: 16) {
                        CustomTextField(title: "Kullanıcı Adı", placeholder: "Kullanıcı adınızı girin", text: $username)
                        
                        CustomTextField(title: "E-posta", placeholder: "E-posta adresinizi girin", text: $email)
                        
                        CustomTextField(title: "Ad", placeholder: "Adınızı girin", text: $firstName)
                        
                        CustomTextField(title: "Soyad", placeholder: "Soyadınızı girin", text: $lastName)
                        
                        CustomTextField(title: "Şifre", placeholder: "Şifrenizi girin", isSecure: true, text: $password)
                        
                        CustomTextField(title: "Şifre Tekrar", placeholder: "Şifrenizi tekrar girin", isSecure: true, text: $confirmPassword)
                        
                        Button(action: {
                            viewModel.register(
                                username: username,
                                email: email,
                                firstName: firstName,
                                lastName: lastName,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                            
                            if viewModel.isAuthenticated {
                                dismiss()
                            }
                        }) {
                            Text("Kayıt Ol")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    // Giriş yapma bağlantısı
                    Button("Zaten hesabınız var mı? Giriş Yap") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: AuthViewModel())
    }
} 