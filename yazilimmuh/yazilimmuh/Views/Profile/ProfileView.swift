import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profil başlığı
                    VStack(spacing: 16) {
                        // Profil fotoğrafı
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        // Ad Soyad
                        if let user = authViewModel.currentUser {
                            Text("\(user.firstName) \(user.lastName)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    
                    // Kullanıcı bilgileri
                    VStack(spacing: 16) {
                        // Bölüm başlığı
                        HStack {
                            Text("Hesap Bilgileri")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if let user = authViewModel.currentUser {
                            // E-posta
                            HStack {
                                Image(systemName: "envelope")
                                    .frame(width: 24)
                                    .foregroundColor(.gray)
                                
                                Text("E-posta")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(user.email)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            // Katılma tarihi
                            HStack {
                                Image(systemName: "calendar")
                                    .frame(width: 24)
                                    .foregroundColor(.gray)
                                
                                Text("Katılma Tarihi")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(formattedDate(user.joinDate))
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // Çıkış yap butonu
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack {
                                Spacer()
                                
                                Text("Çıkış Yap")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Profil")
        }
    }
    
    // Tarih formatla
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        authViewModel.currentUser = User.example
        return ProfileView(authViewModel: authViewModel)
    }
} 