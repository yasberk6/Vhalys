import SwiftUI
import Firebase

struct IdeasListView: View {
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingAddIdea = false
    @State private var showingIdeaDetail: Idea?
    @State private var showSearchBar = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Arama Barı
                if showSearchBar {
                    SearchBar(text: $viewModel.searchText, onCommit: {
                        viewModel.searchIdeas()
                    })
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Akış seçici (Senin İçin / Takip Ettiklerin)
                Picker("Akış", selection: $viewModel.feedType) {
                    Text("Senin İçin").tag(IdeasViewModel.FeedType.forYou)
                    Text("Takip Ettiklerin").tag(IdeasViewModel.FeedType.following)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Kategori filtreleme
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Tümü butonu
                        Button(action: {
                            viewModel.filterIdeasByCategory(nil)
                        }) {
                            Text("Tümü")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(viewModel.selectedCategory == nil ? .white : .primary)
                                .cornerRadius(16)
                        }
                        
                        // Kategori butonları
                        ForEach(viewModel.categories) { category in
                            Button(action: {
                                viewModel.filterIdeasByCategory(category)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: category.iconName)
                                        .font(.caption)
                                    
                                    Text(category.name)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory?.id == category.id ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(viewModel.selectedCategory?.id == category.id ? .white : .primary)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Arama sonuçları veya normal fikirler listesi
                ScrollView {
                    if viewModel.isSearching {
                        // Arama yaparken yüklenme göstergesi
                        VStack {
                            ProgressView()
                                .padding()
                            Text("Aranıyor...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else if !viewModel.searchText.isEmpty && viewModel.searchResults.isEmpty {
                        // Arama sonucu yok
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding()
                            
                            Text("\"\(viewModel.lastSearchQuery)\" ile ilgili sonuç bulunamadı")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Aramayı Temizle") {
                                viewModel.clearSearch()
                            }
                            .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        LazyVStack(spacing: 16) {
                            // Arama yapılmışsa arama sonuçlarını, yapılmamışsa akış türüne göre fikirleri göster
                            let ideasToShow = !viewModel.searchText.isEmpty ? 
                                viewModel.searchResults : 
                                viewModel.getIdeasForCurrentFeed()
                            
                            if ideasToShow.isEmpty && viewModel.feedType == .following {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding()
                                    
                                    Text("Takip ettiğin kişilerin fikirleri burada görünecek")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Fikirlerini görmek istediğin kişileri takip etmeye başla")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    
                                    Button("Kullanıcıları Keşfet") {
                                        // Burada kullanıcı keşfetme sayfasına gidilebilir
                                        viewModel.feedType = .forYou
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .padding(.top, 8)
                                }
                                .padding(.top, 50)
                                .padding(.horizontal)
                            } else {
                                ForEach(ideasToShow) { idea in
                                    IdeaCard(
                                        idea: idea,
                                        onLike: {
                                            viewModel.likeIdea(idea)
                                        },
                                        onTap: {
                                            showingIdeaDetail = idea
                                        },
                                        isLiked: viewModel.isIdeaLikedByUser(idea.id ?? "")
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Fikirler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddIdea = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                viewModel.clearSearch()
                            }
                        }
                    }) {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
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
    }
    
    // Filtrelenmiş fikirleri zaman sırasına göre getirme
    private var filteredIdeas: [Idea] {
        // Kategoriye göre filtrele ve oluşturma tarihine göre sırala (en yeni üstte)
        let ideas = viewModel.getFilteredIdeas()
        return ideas.sorted { $0.createdAt > $1.createdAt }
    }
}

// Arama barı bileşeni
private struct SearchBar: View {
    @Binding var text: String
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Fikir ara...", text: $text)
                .padding(8)
                .padding(.horizontal, 28)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                                onCommit()
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .onChange(of: text) { newValue in
                    // Her karakter değiştiğinde arama yap
                    onCommit()
                }
        }
    }
}

struct IdeasListView_Previews: PreviewProvider {
    static var previews: some View {
        IdeasListView(
            viewModel: IdeasViewModel(),
            authViewModel: AuthViewModel()
        )
    }
}