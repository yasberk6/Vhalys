import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingAddIdea = false
    @State private var showingIdeaDetail: Idea?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hoş geldin kartı
                    if let user = authViewModel.currentUser {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 140)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Merhaba,")
                                            .font(.title3)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Text("Bugün yeni fikirler keşfetmeye ne dersin?")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Son Bakılan Fikirler
                    if !viewModel.getRecentlyViewedIdeas().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Son Baktığın Fikirler")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.getRecentlyViewedIdeas()) { idea in
                                        RecentIdeaCard(
                                            idea: idea,
                                            onTap: {
                                                showingIdeaDetail = idea
                                            }
                                        )
                                        .frame(width: 280, height: 150)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Kategori keşfi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kategorileri Keşfet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    CategoryCard(
                                        category: category,
                                        onTap: {
                                            viewModel.filterIdeasByCategory(category)
                                            // Burada fikirler tab'ına yönlendirilebilir
                                        }
                                    )
                                    .frame(width: 160, height: 120)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Günün Popüler Fikri
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Günün Popüler Fikirleri")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            let popularIdeas = viewModel.getPopularIdeas().prefix(3) // En popüler 3 fikri göster
                            
                            if popularIdeas.isEmpty {
                                Text("Henüz popüler fikir bulunmuyor")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(Array(popularIdeas.enumerated()), id: \.element.id) { index, popularIdea in
                                    FeaturedIdeaCard(
                                        idea: popularIdea,
                                        onLike: {
                                            viewModel.likeIdea(popularIdea)
                                        },
                                        onTap: {
                                            showingIdeaDetail = popularIdea
                                        },
                                        isLiked: viewModel.isIdeaLikedByUser(popularIdea.id ?? "")
                                    )
                                    .padding(.horizontal)
                                    
                                    if index < popularIdeas.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Eğer hiç fikir yoksa yeni veri yükleme butonu ekle
                    if viewModel.ideas.isEmpty && !viewModel.isLoading {
                        Section {
                            Button(action: {
                                viewModel.loadExampleData()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.doc.fill")
                                    Text("Örnek verileri yükle")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("InnovHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddIdea = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIdea) {
                AddEditIdeaView(
                    viewModel: viewModel,
                    authorId: authViewModel.currentUser?.id ?? "",
                    authorName: authViewModel.currentUser?.username ?? ""
                )
            }
            .sheet(item: $showingIdeaDetail) { idea in
                IdeaDetailView(
                    idea: idea,
                    viewModel: viewModel,
                    authViewModel: authViewModel
                )
            }
        }
        .onAppear {
            // Popüler fikirleri anlık olarak al
            viewModel.refreshPopularIdeas()
        }
    }
}

// Son bakılan fikir kartı
struct RecentIdeaCard: View {
    let idea: Idea
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                // Kategori etiketi
                Text(idea.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                // Başlık
                Text(idea.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Alt bilgi
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("\(idea.likeCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer(minLength: 8)
                    
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("\(idea.viewCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay(date: idea.viewedAt ?? idea.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .onTapGesture(perform: onTap)
    }
    
    // Tarih formatlama yardımcı fonksiyon
    private func timeAgoDisplay(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Kategori kartı
struct CategoryCard: View {
    let category: Category
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorFromName(category.colorName).opacity(0.15))
            
            VStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(colorFromName(category.colorName))
                
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .onTapGesture(perform: onTap)
    }
    
    // Renk adından SwiftUI Color oluşturma
    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "gray": return .gray
        case "mint": return .mint
        default: return .primary
        }
    }
}

// Öne çıkarılan fikir kartı
struct FeaturedIdeaCard: View {
    let idea: Idea
    let onLike: () -> Void
    let onTap: () -> Void
    let isLiked: Bool
    
    init(idea: Idea, onLike: @escaping () -> Void, onTap: @escaping () -> Void, isLiked: Bool = false) {
        self.idea = idea
        self.onLike = onLike
        self.onTap = onTap
        self.isLiked = isLiked
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 12) {
                // Başlık
                Text(idea.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Açıklama
                Text(idea.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                
                Spacer()
                
                HStack {
                    // Kategori
                    Text(idea.category)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Görüntülenme
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.white)
                        
                        Text("\(idea.viewCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Beğeni butonu
                    Button(action: onLike) {
                        HStack {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(.white)
                            
                            Text("\(idea.likeCount)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .frame(height: 180)
        .onTapGesture(perform: onTap)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        authViewModel.currentUser = User.example
        return HomeView(
            viewModel: IdeasViewModel(),
            authViewModel: authViewModel
        )
    }
} 