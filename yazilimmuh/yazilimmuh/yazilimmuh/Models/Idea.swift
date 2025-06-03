import Foundation
import FirebaseFirestore

struct Idea: Identifiable, Codable {
    var id: String?
    var title: String
    var description: String
    var authorId: String
    var authorName: String
    var category: String
    var createdAt: Date
    var updatedAt: Date
    var likeCount: Int
    var commentCount: Int
    var viewCount: Int // Görüntülenme sayısı
    var viewedAt: Date? // Son görüntülenme tarihi
    
    // Firebase Timestamp dönüşümü için kodlama anahtarları
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case authorId
        case authorName
        case category
        case createdAt
        case updatedAt
        case likeCount
        case commentCount
        case viewCount
        case viewedAt
    }
    
    // Kullanıcı arayüzü için örnek veri
    static let example = Idea(
        id: "idea1",
        title: "Akıllı Şehir Uygulaması",
        description: "Şehir sakinlerinin ulaşım, enerji kullanımı ve atık yönetimi konularında bilgilendirildiği bir uygulama fikri.",
        authorId: "user1",
        authorName: "Ahmet Yılmaz",
        category: "Teknoloji",
        createdAt: Date(),
        updatedAt: Date(),
        likeCount: 15,
        commentCount: 3,
        viewCount: 42, // Görüntülenme sayısı
        viewedAt: nil
    )
    
    static let examples = [
        example,
        Idea(
            id: "idea2",
            title: "Sürdürülebilir Tarım Projesi",
            description: "Yerel çiftçileri destekleyen ve sürdürülebilir tarım uygulamalarını teşvik eden bir platform.",
            authorId: "user2",
            authorName: "Ayşe Demir",
            category: "Tarım",
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86400),
            likeCount: 8,
            commentCount: 2,
            viewCount: 19, // Görüntülenme sayısı
            viewedAt: nil
        ),
        Idea(
            id: "idea3",
            title: "Eğitim Mentorluk Ağı",
            description: "Öğrencileri profesyonellerle buluşturan bir mentorluk ağı kurma fikri.",
            authorId: "user3",
            authorName: "Mehmet Kaya",
            category: "Eğitim",
            createdAt: Date().addingTimeInterval(-172800),
            updatedAt: Date().addingTimeInterval(-172800),
            likeCount: 23,
            commentCount: 7,
            viewCount: 67, // Görüntülenme sayısı
            viewedAt: nil
        )
    ]
} 