import SwiftUI

struct AddEditIdeaView: View {
    @ObservedObject var viewModel: IdeasViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Fikir bilgileri
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category?
    
    // Kullanıcı bilgileri
    let authorId: String
    let authorName: String
    
    // Düzenleme modu için
    var ideaToEdit: Idea?
    
    init(viewModel: IdeasViewModel, authorId: String, authorName: String, ideaToEdit: Idea? = nil) {
        self.viewModel = viewModel
        self.authorId = authorId
        self.authorName = authorName
        self.ideaToEdit = ideaToEdit
        
        if let idea = ideaToEdit {
            _title = State(initialValue: idea.title)
            _description = State(initialValue: idea.description)
            
            if let category = viewModel.categories.first(where: { $0.name == idea.category }) {
                _selectedCategory = State(initialValue: category)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık alanı
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Başlık")
                            .font(.headline)
                        
                        TextField("Fikrinizin başlığını girin", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Açıklama alanı
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Açıklama")
                            .font(.headline)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 150)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Kategori seçimi
                    CategoryPickerView(
                        categories: viewModel.categories,
                        selectedCategory: $selectedCategory
                    )
                    
                    // Kaydet butonu
                    Button(action: saveIdea) {
                        Text(ideaToEdit == nil ? "Fikri Ekle" : "Fikri Güncelle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle(ideaToEdit == nil ? "Yeni Fikir" : "Fikri Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Form validasyonu
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && selectedCategory != nil
    }
    
    // Fikir kaydetme işlemi
    private func saveIdea() {
        guard isFormValid, let category = selectedCategory else { return }
        
        if let idea = ideaToEdit {
            // Mevcut fikri güncelle
            viewModel.updateIdea(idea, title: title, description: description, category: category.name)
        } else {
            // Yeni fikir ekle
            viewModel.addIdea(
                title: title,
                description: description,
                category: category.name,
                authorId: authorId,
                authorName: authorName
            )
        }
        
        dismiss()
    }
}

struct AddEditIdeaView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditIdeaView(
            viewModel: IdeasViewModel(),
            authorId: "user1",
            authorName: "Test User"
        )
    }
} 