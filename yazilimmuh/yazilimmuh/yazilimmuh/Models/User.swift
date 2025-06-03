import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String?
    var username: String
    var email: String
    var firstName: String
    var lastName: String
    var joinDate: Date
    var recentlyViewedIdeas: [String]?
    var followersCount: Int
    var followingCount: Int
    var bio: String?
    var profileImageUrl: String?
    
    // Firebase Timestamp dönüşümü için kodlama anahtarları
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case firstName
        case lastName
        case joinDate
        case recentlyViewedIdeas
        case followersCount
        case followingCount
        case bio
        case profileImageUrl
    }
    
    // Kullanıcı arayüzü için örnek veri
    static let example = User(
        id: "user1",
        username: "testUser",
        email: "test@example.com",
        firstName: "Ahmet",
        lastName: "Yılmaz",
        joinDate: Date(),
        recentlyViewedIdeas: [],
        followersCount: 0,
        followingCount: 0,
        bio: "Yazılım Mühendisliği öğrencisi",
        profileImageUrl: nil
    )
} 