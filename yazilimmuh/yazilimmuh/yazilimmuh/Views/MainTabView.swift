import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var ideasViewModel = IdeasViewModel()
    @StateObject private var followViewModel = FollowViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            HomeView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
                .tag(0)
            
            // Tüm Fikirler
            IdeasListView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Fikirler", systemImage: "lightbulb")
                }
                .tag(1)
            
            // Popüler Fikirler
            PopularIdeasView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Popüler", systemImage: "star")
                }
                .tag(2)
            
            // Bildirimler
            NotificationsView(viewModel: notificationViewModel)
                .tabItem {
                    Label("Bildirimler", systemImage: "bell")
                }
                .badge(notificationViewModel.unreadCount > 0 ? "\(notificationViewModel.unreadCount)" : nil)
                .tag(3)
            
            // Profil
            ProfileView(
                user: authViewModel.currentUser ?? User.example,
                isCurrentUser: true,
                authViewModel: authViewModel,
                followViewModel: followViewModel,
                ideasViewModel: ideasViewModel
            )
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
                .tag(4)
        }
        .accentColor(.themePrimary)
        .onAppear {
            // Tab bar görünümünü özelleştir
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.themeBackground)
            
            // Tab çubuğunun normal durumdaki görünümü
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(Color.themeTextSecondary)
            ]
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.themeTextSecondary)
            
            // Tab çubuğunun seçili durumdaki görünümü
            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(Color.themePrimary)
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.themePrimary)
            
            // Görünümü UITabBar'a ayarla
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .background(Color.themeBackground)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        authViewModel.currentUser = User.example
        authViewModel.isAuthenticated = true
        
        let notificationViewModel = NotificationViewModel()
        
        return MainTabView(
            authViewModel: authViewModel,
            notificationViewModel: notificationViewModel
        )
        .environmentObject(ThemeManager())
    }
} 