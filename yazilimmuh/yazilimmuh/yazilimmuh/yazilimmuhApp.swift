//
//  yazilimmuhApp.swift
//  yazilimmuh
//
//  Created by Yaşar Berk Irgatoğlu on 16.04.2025.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Bildirim izinleri için kullanıcı bildirim merkezi delegesini ayarla
        UNUserNotificationCenter.current().delegate = self
        
        // NavigationBar görünümünü özelleştir
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.themeBackground)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.themeTextPrimary)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.themeTextPrimary)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.themePrimary)
        
        return true
    }
    
    // Uzak bildirim kaydı başarılı
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // APNs token'ı burada kullanılabilir
        print("Device token received: \(deviceToken)")
    }
    
    // Uzak bildirim kaydı başarısız
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Uzak bildirim kaydı başarısız oldu: \(error.localizedDescription)")
    }
    
    // Uygulama açıkken bildirim alındığında
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Uygulama açıkken bildirimleri göster
        completionHandler([.banner, .sound, .badge])
    }
    
    // Bildirime tıklandığında
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Bildirimin tipine göre işlemler yapılabilir
        if let type = userInfo["type"] as? String {
            // İlgili ekrana yönlendirme veya diğer işlemler
            print("Bildirim tipine göre işlem: \(type)")
        }
        
        completionHandler()
    }
}

@main
struct yazilimmuhApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView(authViewModel: authViewModel, notificationViewModel: notificationViewModel)
                    .preferredColorScheme(.light) // Başlangıçta light mode tercih edilebilir
                    .onAppear {
                        // Kullanıcı oturum açtığında bildirimleri yükle
                        notificationViewModel.fetchNotifications()
                        
                        // Uygulama başlatıldığında bildirim izinlerini kontrol et
                        if !notificationViewModel.hasPermission {
                            notificationViewModel.requestNotificationPermission()
                        }
                    }
            } else {
                LoginView(authViewModel: authViewModel)
                    .preferredColorScheme(.light) // Başlangıçta light mode tercih edilebilir
            }
        }
    }
}
