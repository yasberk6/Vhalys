import SwiftUI

struct CategoryPickerView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kategori Seçin")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(120))], spacing: 16) {
                    ForEach(categories) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        )
                        .onTapGesture {
                            if selectedCategory?.id == category.id {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(colorFromName(category.colorName).opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(colorFromName(category.colorName))
            }
            
            Text(category.name)
                .font(.subheadline)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(width: 80, height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? colorFromName(category.colorName) : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
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

struct CategoryPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryPickerView(
            categories: Category.examples,
            selectedCategory: .constant(Category.examples.first)
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 