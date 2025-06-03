import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    let user: User
    let isCurrentUser: Bool
    
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var followViewModel: FollowViewModel
    @ObservedObject var ideasViewModel: IdeasViewModel
    
    // Dışarıdan başlangıç takip durumu bilgisini alabilir
    var initialIsFollowing: Bool?
    
    @State private var selectedTab: ProfileTab = .ideas
    @State private var showingEditProfile = false
    @State private var showingFollowersList = false
    @State private var showingFollowingList = false
    @State private var isFollowing: Bool = false
    @State private var isLoading: Bool = false
    
    enum ProfileTab {
        case ideas
        case likedIdeas
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profil başlığı
                VStack(alignment: .center, spacing: 16) {
                    // Profil resmi - daha büyük ve ortada
                    if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                        // Base64 formatındaki görüntüleri de destekle
                        if profileImageUrl.starts(with: "data:image") {
                            // Base64 formatındaki resmi göster
                            if let uiImage = loadImageFromBase64(profileImageUrl) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            } else {
                                // Base64 yüklenemezse varsayılan avatar göster
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                                    .shadow(radius: 3)
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
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                            .shadow(radius: 3)
                    }
                    
                    // Kullanıcı bilgileri - ortalanmış
                    VStack(spacing: 6) {
                        // Ad Soyad - artık en üstte
                        if !user.firstName.isEmpty && !user.lastName.isEmpty {
                            Text("\(user.firstName) \(user.lastName)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        // Kullanıcı adı - artık ad-soyadın altında ve daha küçük
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Bio
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .padding(.top, 4)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                
                // Takip bilgileri
                HStack(spacing: 24) {
                    Spacer()
                    
                    // Fikir sayısı
                    VStack {
                        Text("\(getUserIdeasCount())")
                            .font(.headline)
                        Text("Fikir")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Takipçi sayısı - her zaman tam değeri göstermek için
                    Button(action: {
                        loadFollowersList()
                    }) {
                        VStack {
                            Text("\(getFollowersCount())")
                                .font(.headline)
                            Text("Takipçi")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Takip edilen sayısı - her zaman tam değeri göstermek için
                    Button(action: {
                        loadFollowingList()
                    }) {
                        VStack {
                            Text("\(getFollowingCount())")
                                .font(.headline)
                            Text("Takip")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                
                // Takip / Düzenle Butonu
                HStack {
                    Spacer()
                    
                    if isCurrentUser {
                        // Profili düzenle butonu
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("Profili Düzenle")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    } else {
                        // Takip durumuna göre buton göster
                        if isFollowing {
                            Button(action: {
                                followViewModel.unfollowUser(user)
                            }) {
                                Text("Takiptesin")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(16)
                            }
                            .disabled(followViewModel.isLoading)
                        } else {
                            Button(action: {
                                followViewModel.followUser(user)
                            }) {
                                Text("Takip Et")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .disabled(followViewModel.isLoading)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom)
                
                // Sekme seçici
                Picker("", selection: $selectedTab) {
                    Text("Fikirler").tag(ProfileTab.ideas)
                    Text("Beğeniler").tag(ProfileTab.likedIdeas)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Fikirler veya beğeniler
                if selectedTab == .ideas {
                    // Kullanıcının fikirleri
                    LazyVStack(spacing: 16) {
                        let userIdeas = getUserIdeas()
                        
                        if userIdeas.isEmpty {
                            VStack(spacing: 16) {
                                Text("Henüz fikir paylaşılmamış")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 32)
                                
                                if isCurrentUser {
                                    Text("İlk fikrini paylaşmak için 'Fikirler' sayfasına git")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            ForEach(userIdeas) { idea in
                                IdeaCard(
                                    idea: idea,
                                    onLike: {
                                        ideasViewModel.likeIdea(idea)
                                    },
                                    onTap: {
                                        // Fikir detayına git (burada navigator ile yapılacak)
                                    },
                                    isLiked: ideasViewModel.isIdeaLikedByUser(idea.id ?? "")
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Kullanıcının beğendiği fikirler
                    LazyVStack(spacing: 16) {
                        let likedIdeas = getUserLikedIdeas()
                        
                        if likedIdeas.isEmpty {
                            VStack(spacing: 16) {
                                Text("Henüz beğenilen fikir yok")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 32)
                                
                                if isCurrentUser {
                                    Text("Beğendiğin fikirler burada görünecek")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            ForEach(likedIdeas) { idea in
                                IdeaCard(
                                    idea: idea,
                                    onLike: {
                                        ideasViewModel.likeIdea(idea)
                                    },
                                    onTap: {
                                        // Fikir detayına git (burada navigator ile yapılacak)
                                    },
                                    isLiked: true // Beğenilen fikirler zaten beğenilmiş
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showingFollowersList) {
            FollowListView(
                users: followViewModel.followerUsers,
                title: "Takipçiler",
                authViewModel: authViewModel,
                followViewModel: followViewModel,
                ideasViewModel: ideasViewModel
            )
        }
        .sheet(isPresented: $showingFollowingList) {
            FollowListView(
                users: followViewModel.followingUsers,
                title: "Takip Edilenler",
                authViewModel: authViewModel,
                followViewModel: followViewModel,
                ideasViewModel: ideasViewModel
            )
        }
        .onAppear {
            // İlk açılışta, eğer initialIsFollowing verilmişse onu kullan
            if let initialValue = initialIsFollowing {
                isFollowing = initialValue
                print("Profil görüntüleniyor, dışarıdan gelen takip durumu: \(isFollowing)")
            }
            
            // Kullanıcı bilgilerini yükle
            loadUserData()
        }
        .onChange(of: followViewModel.following) { newValue in
            // Kullanıcı takip listesi değiştiğinde takip durumunu güncelle
            if !isLoading {
                isFollowing = newValue.contains(user.id ?? "")
            }
        }
    }
    
    // Kullanıcının fikirlerini getir
    private func getUserIdeas() -> [Idea] {
        guard let userId = user.id else { return [] }
        return ideasViewModel.ideas.filter { $0.authorId == userId }
    }
    
    // Kullanıcının fikir sayısını getir
    private func getUserIdeasCount() -> Int {
        return getUserIdeas().count
    }
    
    // Kullanıcının beğendiği fikirleri getir
    private func getUserLikedIdeas() -> [Idea] {
        if isCurrentUser {
            // Mevcut kullanıcının beğenileri, userLikedIdeas listesinden alınabilir
            return ideasViewModel.ideas.filter { idea in
                guard let ideaId = idea.id else { return false }
                return ideasViewModel.userLikedIdeas.contains(ideaId)
            }
        } else {
            // Diğer kullanıcıların beğenileri için ek bir API çağrısı gerekebilir
            // Şimdilik boş liste döndür
            return []
        }
    }
    
    // Takipçi sayısını doğru şekilde getir
    private func getFollowersCount() -> Int {
        if let userId = user.id, userId == authViewModel.currentUser?.id {
            // Kendi profilimiz için followViewModel.followers.count kullan
            return followViewModel.followers.count
        } else {
            // Başka birinin profili için user.followersCount kullan
            return user.followersCount
        }
    }
    
    // Takip edilen sayısını doğru şekilde getir
    private func getFollowingCount() -> Int {
        if let userId = user.id, userId == authViewModel.currentUser?.id {
            // Kendi profilimiz için followViewModel.following.count kullan
            return followViewModel.following.count
        } else {
            // Başka birinin profili için user.followingCount kullan
            return user.followingCount
        }
    }
    
    // Takipçiler listesini yükle
    private func loadFollowersList() {
        // Takipçiler butonuna tıklamadan önce takipçileri yükle
        if let userId = user.id {
            followViewModel.loadFollowingAndFollowers(userId: userId)
            showingFollowersList = true
        }
    }
    
    // Takip edilenler listesini yükle
    private func loadFollowingList() {
        // Takip edilenler butonuna tıklamadan önce takip edilenleri yükle
        if let userId = user.id {
            followViewModel.loadFollowingAndFollowers(userId: userId)
            showingFollowingList = true
        }
    }
    
    // Kullanıcı verilerini yükle
    private func loadUserData() {
        print(">>> KRITIK FONKSIYON: loadUserData başladı: \(user.username) için")
        // Kullanıcı verilerini yüklerken loading durumunu aktif et
        isLoading = true
        
        if let userId = user.id, let currentUserId = Auth.auth().currentUser?.uid {
            print(">>> KRITIK BILGI: Kullanıcı ID: \(userId), Mevcut kullanıcı ID: \(currentUserId)")
            
            // ÇOK ÖNEMLİ: Başka birinin profiline baktığımızda, takip edilenleri değiştirmiyoruz.
            // Sadece görüntülüyoruz.
            
            // 1. initialIsFollowing MUTLAKA korunacak
            if let initialValue = initialIsFollowing {
                print(">>> KRITIK: Başlangıç takip durumu kullanıldı: \(initialValue)")
                print(">>> DIKKAT: initialIsFollowing değeri koruma altında")
                isFollowing = initialValue
            } else {
                // 2. initialIsFollowing yoksa, durumu Firebase'den kontrol et
                // Bu durumda takip/takipçi listelerini değiştirmiyoruz
                print(">>> KRITIK: Takip durumu Firebase'den kontrol ediliyor...")
                
                // Mevcut kullanıcı başka birini takip ediyor mu?
                let followReference = followViewModel.db.collection("users").document(currentUserId)
                    .collection("following").document(userId)
                
                followReference.getDocument { snapshot, error in
                    if let error = error {
                        print(">>> HATA: Takip durumu kontrol edilirken hata: \(error)")
                        self.isLoading = false
                        return
                    }
                    
                    // Firebase'deki gerçek takip durumunu kullan
                    let isReallyFollowed = snapshot?.exists ?? false
                    print(">>> KRITIK: Firebase'de takip durumu: \(isReallyFollowed ? "TAKİPTE" : "TAKİPTE DEĞİL")")
                    
                    // Takip durumunu belirle
                    DispatchQueue.main.async {
                        self.isFollowing = isReallyFollowed
                    }
                }
            }
            
            // 3. Sadece görüntülenen kullanıcının takip bilgilerini yükle
            // Burada takip listesini DEĞİŞTİRMİYORUZ, sadece GÖRÜNTÜLÜYORUZ
            print(">>> \(user.username) kullanıcısının takip/takipçilerini yüklüyoruz (GORUNTULEME ICIN)...")
            
            // Takip ve takipçi bilgilerini yüklüyoruz sadece profil bilgileri için
            // Bu takip durumunu DEĞİŞTİRMEZ
            followViewModel.fetchUserById(userId) { _ in
                print(">>> KRITIK: Kullanıcı bilgileri güncellendi: \(self.user.username)")
                self.isLoading = false
            }
        } else {
            print(">>> HATA: Kullanıcı ID veya mevcut kullanıcı ID bulunamadı")
            isLoading = false
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

// Takipçiler ve Takip Edilenler Listesi
struct FollowersListView: View {
    let users: [User]
    let title: String
    @ObservedObject var followViewModel: FollowViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var ideasViewModel: IdeasViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUser: User? = nil
    @State private var showingUserProfile = false
    
    var body: some View {
        NavigationView {
            List {
                if users.isEmpty {
                    Text("Henüz \(title.lowercased()) yok")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(users) { user in
                        HStack {
                            // Profil resmi ve kullanıcı bilgileri
                            Button(action: {
                                selectedUser = user
                                // Kullanıcı profiline tıklamadan önce, takip durumunu doğru şekilde belirliyoruz
                                let isFollowed = isUserFollowed(user)
                                print("Kullanıcı profiline tıklandı: \(user.username), Takip durumu: \(isFollowed)")
                                showingUserProfile = true
                            }) {
                                HStack {
                                    // Profil resmi
                                    if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
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
                            
                            // Takip/Takipten çıkar butonu - bu kısmı ayrı bir butona çevirdik
                            if let userId = user.id, let currentUserId = authViewModel.currentUser?.id, userId != currentUserId {
                                if isUserFollowed(user) {
                                    Button(action: {
                                        followViewModel.unfollowUser(user)
                                        // Takip durumu takip listesi değiştiğinde otomatik güncellenecek
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
                                        // Takip durumu takip listesi değiştiğinde otomatik güncellenecek
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
                        .padding(.vertical, 4)
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
        // Firebase'deki takip listesi ile karşılaştır
        let isFollow = followViewModel.following.contains(userId)
        print(">>> isUserFollowed: \(user.username) -> Takip durumu: \(isFollow ? "TAKİPTE" : "TAKİPTE DEĞİL")")
        return isFollow
    }
}

// UserProfileSheet - Temiz bir şekilde profil gösterimi için
struct UserProfileSheet: View {
    let user: User
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var followViewModel: FollowViewModel
    @ObservedObject var ideasViewModel: IdeasViewModel
    let isFollowed: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ProfileView(
                user: user,
                isCurrentUser: authViewModel.currentUser?.id == user.id,
                authViewModel: authViewModel,
                followViewModel: followViewModel,
                ideasViewModel: ideasViewModel,
                initialIsFollowing: isFollowed
            )
            
            // Kapatma butonu
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            print(">>> PROFIL ACILIYOR: \(user.username), mevcut takip durumu: \(isFollowed)")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(
                user: User.example,
                isCurrentUser: true,
                authViewModel: AuthViewModel(),
                followViewModel: FollowViewModel(),
                ideasViewModel: IdeasViewModel()
            )
        }
    }
} 