import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var ideasViewModel = IdeasViewModel()
    
    var body: some View {
        TabView {
            // Ana Sayfa
            HomeView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
            
            // Tüm Fikirler
            IdeasListView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Fikirler", systemImage: "lightbulb")
                }
            
            // Popüler Fikirler
            PopularIdeasView(viewModel: ideasViewModel, authViewModel: authViewModel)
                .tabItem {
                    Label("Popüler", systemImage: "star")
                }
            
            // Profil
            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        authViewModel.currentUser = User.example
        authViewModel.isAuthenticated = true
        return MainTabView(authViewModel: authViewModel)
    }
} 