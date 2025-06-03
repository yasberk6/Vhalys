import SwiftUI

class ThemeManager: ObservableObject {
    enum Theme: String {
        case light, dark, system
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
    }
    
    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "userTheme")
        }
    }
    
    init() {
        // Kullanıcının tercihini UserDefaults'tan oku
        let savedTheme = UserDefaults.standard.string(forKey: "userTheme")
        
        if let savedTheme = savedTheme,
           let theme = Theme(rawValue: savedTheme) {
            self.theme = theme
        } else {
            // Varsayılan olarak sistem tercihini kullan
            self.theme = .system
        }
    }
} 
 