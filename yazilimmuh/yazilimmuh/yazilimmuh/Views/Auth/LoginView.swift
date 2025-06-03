import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    @State private var isLoading = false
    @State private var animateLogo = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var isResettingPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                Color.themeBackground
                    .ignoresSafeArea()
                
                // İçerik
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo ve başlık
                        VStack(spacing: 16) {
                            // Logo
                            Image("VhalysLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 160, height: 80)
                                .scaleEffect(animateLogo ? 1.05 : 1.0)
                                .shadow(color: Color.black.opacity(0.2), radius: animateLogo ? 8 : 4, x: 0, y: 0)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        animateLogo = true
                                    }
                                }
                            
                            Text("Vhalys")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.themeTextPrimary)
                            
                            Text("Fikirlerinizi paylaşın, diğer fikirlerden ilham alın")
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 40)
                        
                        // Hata mesajı
                        if let error = authViewModel.loginError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.themeAccent)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                        
                        // Giriş formu
                        VStack(spacing: 18) {
                            CustomTextField(
                                title: "E-posta",
                                placeholder: "E-posta adresinizi girin",
                                text: $email,
                                icon: "envelope",
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                title: "Şifre",
                                placeholder: "Şifrenizi girin",
                                isSecure: true,
                                text: $password,
                                icon: "lock"
                            )
                            
                            // Şifremi Unuttum bağlantısı
                            HStack {
                                Spacer()
                                Button("Şifremi Unuttum") {
                                    resetEmail = email // Mevcut e-posta alanını önceden doldur
                                    showForgotPassword = true
                                }
                                .font(.footnote)
                                .foregroundColor(.themePrimary)
                                .padding(.bottom, 5)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isLoading = true
                                    authViewModel.login(email: email, password: password)
                                    // Firebase entegrasyonu nedeniyle, login işlemi asenkron
                                    // olduğundan isLoading'i otomatik kapatamayız.
                                    // Gerçek uygulamada bu durum completion handler ile yönetilmelidir.
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isLoading = false
                                    }
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Giriş Yap")
                                }
                            }
                            .primaryButtonStyle()
                            .disabled(email.isEmpty || password.isEmpty || isLoading)
                        }
                        .padding(.horizontal)
                        
                        // Kayıt olma bağlantısı
                        VStack(spacing: 5) {
                            Text("Henüz hesabınız yok mu?")
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                            
                            Button("Kayıt Ol") {
                                showRegistration = true
                            }
                            .font(.headline)
                            .foregroundColor(.themePrimary)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegistration) {
                RegisterView(authViewModel: authViewModel)
            }
            .sheet(isPresented: $showForgotPassword) {
                VStack(spacing: 20) {
                    Text("Şifre Sıfırlama")
                        .font(.title)
                        .fontWeight(.bold)
                        
                    if let message = authViewModel.resetPasswordMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(message.contains("hatası") ? .red : .green)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        Text("Şifrenizi sıfırlamak için e-posta adresinizi girin. Sıfırlama bağlantısı e-posta adresinize gönderilecektir.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    CustomTextField(
                        title: "E-posta",
                        placeholder: "E-posta adresinizi girin",
                        text: $resetEmail,
                        icon: "envelope",
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button("İptal") {
                            showForgotPassword = false
                            authViewModel.resetPasswordMessage = nil
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            isResettingPassword = true
                            
                            authViewModel.resetPassword(email: resetEmail) { success in
                                isResettingPassword = false
                                if success {
                                    // Başarılı olduğunda modal kapatılmasın, kullanıcı mesajı görsün
                                }
                            }
                        }) {
                            if isResettingPassword {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Sıfırlama Bağlantısı Gönder")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(resetEmail.isEmpty || isResettingPassword)
                    }
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: 400)
                .presentationDetents([.height(350)])
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authViewModel: AuthViewModel())
    }
} 