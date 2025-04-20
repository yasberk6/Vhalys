import SwiftUI

struct IdeasListView: View {
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingAddIdea = false
    @State private var showingIdeaDetail: Idea?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                // Fikirler listesi
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredIdeas) { idea in
                            IdeaCard(
                                idea: idea,
                                onLike: {
                                    viewModel.likeIdea(idea)
                                },
                                onTap: {
                                    showingIdeaDetail = idea
                                }
                            )
                        }
                    }
                    .padding()
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
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

struct IdeasListView_Previews: PreviewProvider {
    static var previews: some View {
        IdeasListView(
            viewModel: IdeasViewModel(),
            authViewModel: AuthViewModel()
        )
    }
}