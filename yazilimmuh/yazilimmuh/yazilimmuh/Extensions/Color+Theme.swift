import SwiftUI

extension Color {
    static let themePrimary = Color("Primary")
    static let themeSecondary = Color("Secondary")
    static let themeBackground = Color("Background")
    static let themeAccent = Color("Accent")
    static let themeTextPrimary = Color("TextPrimary")
    static let themeTextSecondary = Color("TextSecondary")
    
    // Kategoriler için renkler
    static func categoryColor(_ name: String) -> Color {
        switch name {
        case "blue": return .themePrimary
        case "green": return .themeSecondary
        case "red": return .themeAccent
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "gray": return .gray
        case "mint": return .mint
        default: return .primary
        }
    }
} 