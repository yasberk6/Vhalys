import SwiftUI

struct NotificationDetailView: View {
    let notification: NotificationViewModel.AppNotification
    let viewModel: NotificationViewModel
    @ObservedObject var authViewModel = AuthViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDeleteConfirmation = false
    @StateObject private var ideasViewModel = IdeasViewModel()
    @State private var navigateToIdea = false
    @State private var selectedIdea: Idea?
    @State private var hasMarkedAsRead = false
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(notification.type.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: notification.type.icon)
                                .foregroundColor(notification.type.color)
                                .font(.system(size: 22, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(notification.timeAgo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Message content
                    Text(notification.message)
                        .font(.body)
                        .padding(.vertical, 8)
                    
                    // Related content (if any)
                    if let relatedId = notification.relatedContentId, let contentType = notification.relatedContentType {
                        Divider()
                        
                        Button(action: {
                            handleRelatedContentNavigation(contentId: relatedId, contentType: contentType)
                        }) {
                            HStack {
                                Text("İlgili İçeriğe Git")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding()
            }
            
            // Navigation link (separate from the main content)
            NavigationLink(destination: destinationView, isActive: $navigateToIdea) {
                EmptyView()
            }
        }
        .onAppear {
            if !notification.isRead && !hasMarkedAsRead {
                // Sadece bir kez okundu olarak işaretle
                viewModel.markAsRead(notification)
                hasMarkedAsRead = true
                #if DEBUG
                print("DEBUG - NotificationDetailView: Bildirim okundu olarak işaretlendi")
                #endif
            } else {
                #if DEBUG
                print("DEBUG - NotificationDetailView: Bildirim zaten okundu olarak işaretlenmiş")
                #endif
            }
        }
        .navigationTitle("Bildirim Detayı")
        .toolbar {
            Menu {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Bildirimi Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .confirmationDialog(
            "Bu bildirimi silmek istediğinize emin misiniz?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                viewModel.deleteNotification(notification)
                presentationMode.wrappedValue.dismiss()
            }
            Button("İptal", role: .cancel) {}
        }
    }
    
    // Extracted destination view to simplify the navigation logic
    @ViewBuilder
    private var destinationView: some View {
        if let idea = selectedIdea {
            IdeaDetailView(
                idea: idea,
                viewModel: ideasViewModel,
                authViewModel: authViewModel
            )
        } else {
            EmptyView()
        }
    }
    
    // Handle navigation to related content
    private func handleRelatedContentNavigation(contentId: String, contentType: String) {
        #if DEBUG
        print("DEBUG - İlgili içeriğe gidiliyor: \(contentType) - \(contentId)")
        #endif
        
        // Navigate based on content type
        switch contentType {
        case "idea":
            // Fetch and navigate to the idea
            ideasViewModel.fetchIdeaById(contentId) { idea in
                if let idea = idea {
                    self.selectedIdea = idea
                    self.navigateToIdea = true
                } else {
                    #if DEBUG
                    print("DEBUG - Fikir bulunamadı: \(contentId)")
                    #endif
                }
            }
        default:
            #if DEBUG
            print("DEBUG - Bilinmeyen içerik türü: \(contentType)")
            #endif
        }
    }
} 