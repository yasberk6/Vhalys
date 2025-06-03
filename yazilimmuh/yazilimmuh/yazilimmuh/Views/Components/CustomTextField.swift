import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    var isSecure: Bool = false
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    
    @State private var isEditing = false
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık
            Text(title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            
            // Metin alanı
            HStack {
                // Sol taraf ikonu (opsiyonel)
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isEditing ? .themePrimary : .themeTextSecondary)
                        .padding(.leading, 8)
                }
                
                // Asıl metin alanı
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .padding(12)
                        .background(Color.themeBackground)
                        .onTapGesture {
                            isEditing = true
                        }
                } else {
                    TextField(placeholder, text: $text, onEditingChanged: { editing in
                        isEditing = editing
                    })
                    .keyboardType(keyboardType)
                    .padding(12)
                    .background(Color.themeBackground)
                }
                
                // Şifre görünürlük butonu (Sadece güvenli alanlar için)
                if isSecure {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEditing ? Color.themePrimary : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// Önizleme
struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTextField(
                title: "E-posta",
                placeholder: "E-posta adresinizi girin",
                text: .constant(""),
                icon: "envelope"
            )
            
            CustomTextField(
                title: "Şifre",
                placeholder: "Şifrenizi girin",
                isSecure: true,
                text: .constant(""),
                icon: "lock"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 