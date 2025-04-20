import Foundation
import SwiftUI

class IdeasViewModel: ObservableObject {
    @Published var ideas: [Idea] = Idea.examples
    @Published var categories: [Category] = Category.examples
    @Published var selectedCategory: Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recentlyViewedIdeas: [Idea] = []
    
    // Maksimum son bakılan fikir sayısı
    private let maxRecentlyViewedCount = 5
    
    // Fikir görüntüleme (fikir detayına bakıldığında çağrılır)
    func viewIdea(_ idea: Idea) {
        // İlk önce fikri güncelle (görüntülenme tarihini ekle)
        var updatedIdea = idea
        updatedIdea.viewedAt = Date()
        
        // Fikir listesindeki orijinal fikri güncelle
        if let index = ideas.firstIndex(where: { $0.id == idea.id }) {
            ideas[index] = updatedIdea
        }
        
        // Zaten listenin en başındaysa bir şey yapma
        if let firstIndex = recentlyViewedIdeas.firstIndex(where: { $0.id == idea.id }),
           firstIndex == 0 {
            return
        }
        
        // Fikir zaten listede varsa, listeden çıkar
        recentlyViewedIdeas.removeAll(where: { $0.id == idea.id })
        
        // Fikri listenin en başına ekle
        recentlyViewedIdeas.insert(updatedIdea, at: 0)
        
        // Liste maksimum boyutu aşıyorsa sondan kırp
        if recentlyViewedIdeas.count > maxRecentlyViewedCount {
            recentlyViewedIdeas = Array(recentlyViewedIdeas.prefix(maxRecentlyViewedCount))
        }
    }
    
    // Son bakılan fikirleri getir
    func getRecentlyViewedIdeas() -> [Idea] {
        return recentlyViewedIdeas
    }
    
    // Fikir ekleme
    func addIdea(title: String, description: String, category: String, authorId: String, authorName: String) {
        let newIdea = Idea(
            id: UUID().uuidString,
            title: title,
            description: description,
            authorId: authorId,
            authorName: authorName,
            category: category,
            createdAt: Date(),
            updatedAt: Date(),
            likeCount: 0,
            commentCount: 0,
            viewedAt: nil
        )
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        ideas.insert(newIdea, at: 0)
    }
    
    // Fikir güncelleme
    func updateIdea(_ idea: Idea, title: String, description: String, category: String) {
        guard let index = ideas.firstIndex(where: { $0.id == idea.id }) else { return }
        
        var updatedIdea = idea
        updatedIdea.title = title
        updatedIdea.description = description
        updatedIdea.category = category
        updatedIdea.updatedAt = Date()
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        ideas[index] = updatedIdea
        
        // Son bakılanlar listesini de güncelle
        if let recentIndex = recentlyViewedIdeas.firstIndex(where: { $0.id == idea.id }) {
            recentlyViewedIdeas[recentIndex] = updatedIdea
        }
    }
    
    // Fikir silme
    func deleteIdea(_ idea: Idea) {
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        ideas.removeAll { $0.id == idea.id }
        
        // Son bakılanlar listesinden de sil
        recentlyViewedIdeas.removeAll { $0.id == idea.id }
    }
    
    // Fikir beğenme
    func likeIdea(_ idea: Idea) {
        guard let index = ideas.firstIndex(where: { $0.id == idea.id }) else { return }
        
        var updatedIdea = idea
        updatedIdea.likeCount += 1
        
        // Backend entegrasyonu burada yapılacak
        // Şimdilik sadece frontend için verileri güncelliyoruz
        ideas[index] = updatedIdea
        
        // Son bakılanlar listesini de güncelle
        if let recentIndex = recentlyViewedIdeas.firstIndex(where: { $0.id == idea.id }) {
            recentlyViewedIdeas[recentIndex] = updatedIdea
        }
    }
    
    // Kategoriye göre fikirleri filtreleme
    func filterIdeasByCategory(_ category: Category?) {
        selectedCategory = category
    }
    
    // Popüler fikirleri getirme
    func getPopularIdeas() -> [Idea] {
        return ideas.sorted { $0.likeCount > $1.likeCount }
    }
    
    // Yeni fikirleri getirme
    func getRecentIdeas() -> [Idea] {
        return ideas.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Filtrelenmiş fikirleri getirme
    func getFilteredIdeas() -> [Idea] {
        if let selectedCategory = selectedCategory {
            return ideas.filter { $0.category == selectedCategory.name }
        } else {
            return ideas
        }
    }
} 