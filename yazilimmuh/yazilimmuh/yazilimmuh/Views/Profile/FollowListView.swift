import SwiftUI

struct FollowListView: View {
    let users: [User]
    let title: String
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var followViewModel: FollowViewModel
    @ObservedObject var ideasViewModel: IdeasViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedUser: User? = nil
    @State private var showingUserProfile = false
    
    var body: some View {
        NavigationView {
            List {
                if users.isEmpty {
                    Text(title == "Takipçiler" ? "Henüz takipçi yok" : "Henüz takip edilen kullanıcı yok")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets())
                        .background(Color(UIColor.systemGroupedBackground))
                } else {
                    ForEach(users) { user in
                        Button(action: {
                            selectedUser = user
                            showingUserProfile = true
                        }) {
                            HStack {
                                // Profil resmi
                                if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                                    // Base64 formatındaki görüntüleri de destekle
                                    if profileImageUrl.starts(with: "data:image") {
                                        // Base64 formatındaki resmi göster
                                        if let uiImage = loadImageFromBase64(profileImageUrl) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                        } else {
                                            // Base64 yüklenemezse varsayılan avatar göster
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(.gray)
                                                .frame(width: 40, height: 40)
                                        }
                                    } else {
                                        // Normal URL'den resmi göster
                                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.gray)
                                        .frame(width: 40, height: 40)
                                }
                                
                                // Kullanıcı bilgileri
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.username)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    if !user.firstName.isEmpty && !user.lastName.isEmpty {
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Takip/Takipten çıkar butonu
                        if let userId = user.id, let currentUserId = authViewModel.currentUser?.id, userId != currentUserId {
                            if isUserFollowed(user) {
                                Button(action: {
                                    followViewModel.unfollowUser(user)
                                }) {
                                    Text("Takiptesin")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(followViewModel.isLoading)
                            } else {
                                Button(action: {
                                    followViewModel.followUser(user)
                                }) {
                                    Text("Takip Et")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(followViewModel.isLoading)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
            .onAppear {
                // Her zaman güncel takip bilgilerini yükle
                if let currentUserId = authViewModel.currentUser?.id {
                    followViewModel.loadFollowingAndFollowers(userId: currentUserId)
                }
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            if let selectedUser = selectedUser {
                UserProfileSheet(
                    user: selectedUser,
                    authViewModel: authViewModel,
                    followViewModel: followViewModel,
                    ideasViewModel: ideasViewModel,
                    isFollowed: isUserFollowed(selectedUser),
                    onDismiss: { showingUserProfile = false }
                )
            }
        }
    }
    
    // Kullanıcının takip edilip edilmediğini kontrol et
    private func isUserFollowed(_ user: User) -> Bool {
        guard let userId = user.id else { return false }
        return followViewModel.following.contains(userId)
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