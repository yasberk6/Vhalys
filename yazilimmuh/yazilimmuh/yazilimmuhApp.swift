//
//  yazilimmuhApp.swift
//  yazilimmuh
//
//  Created by Yaşar Berk Irgatoğlu on 16.04.2025.
//

import SwiftUI

@main
struct yazilimmuhApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView(authViewModel: authViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
    }
}
