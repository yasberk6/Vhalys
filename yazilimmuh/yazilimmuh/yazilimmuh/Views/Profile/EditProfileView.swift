import SwiftUI
import UIKit

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var authViewModel: AuthViewModel
    
    // Profil bilgileri için state değişkenleri
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    
    // Profil resmi için state değişkenleri
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingImageSourceDialog = false
    
    // Uyarı ve durum state değişkenleri
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profil resmi seçimi
                        VStack {
                            // Profil resmi
                            ZStack {
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                } else if let profileImageUrl = authViewModel.currentUser?.profileImageUrl, !profileImageUrl.isEmpty {
                                    if profileImageUrl.starts(with: "data:image") {
                                        // Base64 formatındaki resmi göster
                                        if let uiImage = loadImageFromBase64(profileImageUrl) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                        } else {
                                            // Base64 yüklenemezse varsayılan avatar göster
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(.gray)
                                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                        }
                                    } else {
                                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                    }
                                } else {
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                }
                                
                                // Değiştir butonu
                                Button(action: {
                                    showingImageSourceDialog = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15))
                                    }
                                }
                                .offset(x: 35, y: 35)
                            }
                            .padding(.bottom, 10)
                            
                            Text("Profil Fotoğrafı")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Form alanları
                        VStack(spacing: 20) {
                            // İsim
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ad")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextField("Adınız", text: $firstName)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            
                            // Soyisim
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Soyad")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextField("Soyadınız", text: $lastName)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            
                            // Kullanıcı Adı
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kullanıcı Adı")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextField("Kullanıcı adınız", text: $username)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .disabled(true)
                                    .foregroundColor(.gray)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                                .padding(.trailing, 12)
                                        }
                                    )
                            }
                            .overlay(
                                VStack {
                                    Spacer()
                                    Text("Kullanıcı adı değiştirilemez")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                }
                            )
                            
                            // Biyografi
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Biyografi")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $bio)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Kaydet Butonu
                        Button(action: updateProfile) {
                            HStack {
                                if authViewModel.isUpdatingProfile {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                
                                Text(authViewModel.isUpdatingProfile ? "Kaydediliyor..." : "Değişiklikleri Kaydet")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                            }
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }
                        .disabled(authViewModel.isUpdatingProfile)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .actionSheet(isPresented: $showingImageSourceDialog) {
                ActionSheet(
                    title: Text("Profil Fotoğrafı Seçin"),
                    message: Text("Profil fotoğrafı nereden seçmek istersiniz?"),
                    buttons: [
                        .default(Text("Fotoğraf Galerisi")) {
                            self.imageSourceType = .photoLibrary
                            self.showingImagePicker = true
                        },
                        .default(Text("Kamera")) {
                            self.imageSourceType = .camera
                            self.showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    selectedImage: $profileImage,
                    isPresented: $showingImagePicker,
                    sourceType: imageSourceType
                )
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    // Kullanıcı bilgilerini yükle
    private func loadUserData() {
        if let user = authViewModel.currentUser {
            firstName = user.firstName
            lastName = user.lastName
            username = user.username
            bio = user.bio ?? ""
        }
    }
    
    // Profil güncelleme işlemi
    private func updateProfile() {
        // Boş alanlar kontrolü
        if firstName.isEmpty || lastName.isEmpty || username.isEmpty {
            alertTitle = "Uyarı"
            alertMessage = "Ad, soyad ve kullanıcı adı alanları boş bırakılamaz"
            showingAlert = true
            return
        }
        
        // Profil güncelleme işlemini başlat
        authViewModel.updateProfile(
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            profileImage: profileImage
        ) { success in
            if success {
                // Başarılı olursa sayfayı kapat
                presentationMode.wrappedValue.dismiss()
            } else {
                // Hata olursa kullanıcıyı bilgilendir
                alertTitle = "Hata"
                alertMessage = authViewModel.profileUpdateMessage ?? "Profil güncellenirken bir hata oluştu"
                showingAlert = true
            }
        }
    }
    
    // Base64'ten UIImage oluşturma yardımcı fonksiyonu
    private func loadImageFromBase64(_ base64String: String) -> UIImage? {
        // "data:image/jpeg;base64," prefixi varsa kaldır
        var base64 = base64String
        if let range = base64.range(of: "base64,") {
            base64 = String(base64[range.upperBound...])
        }
        
        // Base64'ten veri oluştur
        guard let imageData = Data(base64Encoded: base64) else {
            print("Base64'ten veri oluşturulamadı")
            return nil
        }
        
        // UIImage oluştur
        return UIImage(data: imageData)
    }
} 