import Foundation

struct Comment: Identifiable, Codable {
    var id: String
    var ideaId: String
    var authorId: String
    var authorName: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var likeCount: Int
    
    // Kullanıcı arayüzü için örnek veri
    static let example = Comment(
        id: "comment1",
        ideaId: "idea1",
        authorId: "user2",
        authorName: "Ayşe Demir",
        content: "Bu harika bir fikir! Şehrimizdeki trafik sorunlarına çözüm getirebilir.",
        createdAt: Date(),
        updatedAt: Date(),
        likeCount: 5
    )
    
    static let examples = [
        example,
        Comment(
            id: "comment2",
            ideaId: "idea1",
            authorId: "user3",
            authorName: "Mehmet Kaya",
            content: "Enerji tasarrufu açısından büyük potansiyel var.",
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600),
            likeCount: 2
        ),
        Comment(
            id: "comment3",
            ideaId: "idea1",
            authorId: "user4",
            authorName: "Zeynep Yıldız",
            content: "Belediye ile ortak çalışılabilir mi?",
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-7200),
            likeCount: 1
        )
    ]
} 