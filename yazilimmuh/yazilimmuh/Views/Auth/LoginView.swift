import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo ve başlık
                VStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Fikir Platformu")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Fikirlerinizi paylaşın, diğer fikirlerden ilham alın")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 40)
                
                // Hata mesajı
                if let error = viewModel.loginError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Giriş formu
                VStack(spacing: 16) {
                    CustomTextField(title: "E-posta", placeholder: "E-posta adresinizi girin", text: $email)
                    
                    CustomTextField(title: "Şifre", placeholder: "Şifrenizi girin", isSecure: true, text: $password)
                    
                    Button(action: {
                        viewModel.login(email: email, password: password)
                    }) {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                
                // Kayıt olma bağlantısı
                VStack {
                    Text("Henüz hesabınız yok mu?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Kayıt Ol") {
                        showRegistration = true
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .padding()
            .background(Color(.systemBackground).ignoresSafeArea())
            .sheet(isPresented: $showRegistration) {
                RegisterView(viewModel: viewModel)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AuthViewModel())
    }
} 