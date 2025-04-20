import SwiftUI

struct PopularIdeasView: View {
    @ObservedObject var viewModel: IdeasViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingIdeaDetail: Idea?
    @State private var timeFrame: TimeFrame = .allTime
    
    enum TimeFrame {
        case today, week, month, allTime
        
        var title: String {
            switch self {
            case .today: return "Bugün"
            case .week: return "Bu Hafta"
            case .month: return "Bu Ay"
            case .allTime: return "Tüm Zamanlar"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Zaman dilimi seçici
                Picker("Zaman Dilimi", selection: $timeFrame) {
                    Text("Bugün").tag(TimeFrame.today)
                    Text("Bu Hafta").tag(TimeFrame.week)
                    Text("Bu Ay").tag(TimeFrame.month)
                    Text("Tüm Zamanlar").tag(TimeFrame.allTime)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
                    if popularIdeas.isEmpty {
                        VStack {
                            Spacer(minLength: 100)
                            
                            Text("Bu zaman diliminde popüler fikir bulunmuyor")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Spacer()
                        }
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(popularIdeas) { idea in
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
            }
            .navigationTitle("Popüler Fikirler")
            .sheet(item: $showingIdeaDetail) { idea in
                IdeaDetailView(
                    idea: idea,
                    viewModel: viewModel,
                    authViewModel: authViewModel
                )
            }
        }
    }
    
    // Seçilen zaman dilimine göre popüler fikirleri getirme
    private var popularIdeas: [Idea] {
        // Önce kategoriye göre fikirler filtreleniyor
        let filteredByCategory = viewModel.getFilteredIdeas()
        
        // Sonra zaman dilimine göre filtreleniyor
        let filteredByDate = filteredByCategory.filter { idea in
            switch timeFrame {
            case .today:
                // Son 24 saat içindeki fikirler
                return Calendar.current.isDateInToday(idea.createdAt)
            case .week:
                // Son 7 gün içindeki fikirler
                let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return idea.createdAt > oneWeekAgo
            case .month:
                // Son 30 gün içindeki fikirler
                let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                return idea.createdAt > oneMonthAgo
            case .allTime:
                // Tüm zamanlar - filtreleme yok
                return true
            }
        }
        
        // Son olarak beğeni sayısına göre sıralama
        return filteredByDate.sorted { $0.likeCount > $1.likeCount }
    }
}

struct PopularIdeasView_Previews: PreviewProvider {
    static var previews: some View {
        PopularIdeasView(
            viewModel: IdeasViewModel(),
            authViewModel: AuthViewModel()
        )
    }
} 