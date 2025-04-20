import Foundation

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var joinDate: Date
    
    // Kullanıcı arayüzü için örnek veri
    static let example = User(
        id: "user1",
        username: "testUser",
        email: "test@example.com",
        firstName: "Ahmet",
        lastName: "Yılmaz",
        joinDate: Date()
    )
} 