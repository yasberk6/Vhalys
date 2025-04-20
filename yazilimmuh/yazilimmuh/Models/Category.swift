import Foundation

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var iconName: String
    
    // Kategori rengi için temsili bir değer (Color kullanımından kaçınmak için)
    var colorName: String
    
    // Kullanıcı arayüzü için örnek veriler
    static let examples = [
        Category(id: "cat1", name: "Teknoloji", iconName: "desktopcomputer", colorName: "blue"),
        Category(id: "cat2", name: "Eğitim", iconName: "book", colorName: "green"),
        Category(id: "cat3", name: "Sağlık", iconName: "heart", colorName: "red"),
        Category(id: "cat4", name: "Çevre", iconName: "leaf", colorName: "mint"),
        Category(id: "cat5", name: "Tarım", iconName: "sun.max", colorName: "yellow"),
        Category(id: "cat6", name: "Sanat", iconName: "paintpalette", colorName: "purple"),
        Category(id: "cat7", name: "Spor", iconName: "figure.run", colorName: "orange"),
        Category(id: "cat8", name: "Diğer", iconName: "ellipsis", colorName: "gray")
    ]
} 