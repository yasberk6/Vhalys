import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @State private var showSettings = false
    @State private var showDeleteConfirmation = false
    @State private var selectedNotification: NotificationViewModel.AppNotification? = nil
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    // Loading state
                    ProgressView("Yükleniyor...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    ErrorView(message: errorMessage) {
                        viewModel.fetchNotifications()
                    }
                } else if viewModel.notifications.isEmpty {
                    // Empty state
                    EmptyNotificationsView(viewModel: viewModel)
                } else {
                    // Notifications list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                NavigationLink(destination: NotificationDetailView(notification: notification, viewModel: viewModel)) {
                                    NotificationCard(notification: notification)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(action: {
                                        viewModel.markAsRead(notification)
                                    }) {
                                        Label("Okundu olarak işaretle", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        selectedNotification = notification
                                        showDeleteConfirmation = true
                                    }) {
                                        Label("Bildirimi Sil", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        // Manuel yenileme
                        viewModel.fetchNotifications()
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.markAllAsRead()
                        }) {
                            Label("Tümünü Okundu İşaretle", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            showDeleteConfirmation = true
                            selectedNotification = nil
                        }) {
                            Label("Tüm Bildirimleri Sil", systemImage: "trash")
                        }
                        
                        Button(action: {
                            showSettings = true
                        }) {
                            Label("Bildirim Ayarları", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                // Manuel yenileme için refresh butonu
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.fetchNotifications()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .confirmationDialog(
                selectedNotification != nil ? "Bu bildirimi silmek istediğinize emin misiniz?" : "Tüm bildirimleri silmek istediğinize emin misiniz?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sil", role: .destructive) {
                    if let notification = selectedNotification {
                        viewModel.deleteNotification(notification)
                    } else {
                        viewModel.clearAllNotifications()
                    }
                    selectedNotification = nil
                }
                Button("İptal", role: .cancel) {
                    selectedNotification = nil
                }
            }
            .sheet(isPresented: $showSettings) {
                NotificationSettingsView(viewModel: viewModel)
            }
        }
        .onAppear {
            if !hasAppeared {
                #if DEBUG
                print("DEBUG - NotificationsView: İlk kez göründü, bildirimleri yüklüyor")
                #endif
                viewModel.fetchNotifications()
                hasAppeared = true
            } else {
                #if DEBUG
                print("DEBUG - NotificationsView: Tekrar göründü, yeniden yükleme yapılmıyor")
                #endif
            }
        }
    }
}

// MARK: - Helper Views
struct NotificationCard: View {
    let notification: NotificationViewModel.AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .foregroundColor(notification.type.color)
                    .font(.system(size: 16, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(notification.isRead ? 0.8 : 1)
    }
}

struct EmptyNotificationsView: View {
    let viewModel: NotificationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Hiç bildiriminiz yok")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Bildirimleri açarak yeni gelişmelerden haberdar olabilirsiniz")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if !viewModel.hasPermission {
                Button(action: {
                    viewModel.requestNotificationPermission()
                }) {
                    Text("Bildirimleri Aç")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Bir hata oluştu")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: retryAction) {
                Text("Tekrar Dene")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView(viewModel: NotificationViewModel())
    }
} 