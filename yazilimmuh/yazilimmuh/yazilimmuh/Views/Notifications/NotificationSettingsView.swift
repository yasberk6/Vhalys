import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: NotificationViewModel
    @State private var pushNotificationsEnabled = true
    @State private var inAppNotificationsEnabled = true
    @State private var notificationTypes: [NotificationViewModel.NotificationType: Bool] = [
        .like: true,
        .comment: true,
        .newIdea: true,
        .mention: true,
        .system: true
    ]
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Genel")) {
                    Toggle("Push Bildirimleri", isOn: $pushNotificationsEnabled)
                        .onChange(of: pushNotificationsEnabled) { value in
                            if value && !viewModel.hasPermission {
                                viewModel.requestNotificationPermission()
                            }
                        }
                    
                    Toggle("Uygulama İçi Bildirimler", isOn: $inAppNotificationsEnabled)
                }
                
                Section(header: Text("Bildirim Türleri"), footer: Text("Hangi tür bildirimleri almak istediğinizi seçin")) {
                    ForEach(NotificationViewModel.NotificationType.allCases) { type in
                        Toggle(type.title, isOn: Binding(
                            get: { notificationTypes[type] ?? true },
                            set: { notificationTypes[type] = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Bildirim Yönetimi")) {
                    Button(action: {
                        viewModel.markAllAsRead()
                    }) {
                        HStack {
                            Text("Tüm Bildirimleri Okundu İşaretle")
                            Spacer()
                            Image(systemName: "checkmark.circle")
                        }
                    }
                    
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Text("Tüm Bildirimleri Sil")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                #if DEBUG
                Section(header: Text("Geliştirici Seçenekleri")) {
                    Button("Test Bildirimi Ekle") {
                        viewModel.addTestNotification()
                    }
                    
                    Button("5 Test Bildirimi Ekle") {
                        for _ in 0..<5 {
                            viewModel.addTestNotification()
                        }
                    }
                }
                #endif
            }
            .navigationTitle("Bildirim Ayarları")
            .navigationBarItems(trailing: Button("Kaydet") {
                // TODO: Ayarları kaydet
                presentationMode.wrappedValue.dismiss()
            })
            .confirmationDialog(
                "Tüm bildirimleri silmek istediğinize emin misiniz?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sil", role: .destructive) {
                    viewModel.clearAllNotifications()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Bu işlem geri alınamaz.")
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(viewModel: NotificationViewModel.previewModel())
    }
} 