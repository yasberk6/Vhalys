import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    var isSecure: Bool = false
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomTextField(title: "E-posta", placeholder: "E-posta adresinizi girin", text: .constant(""))
            CustomTextField(title: "Şifre", placeholder: "Şifrenizi girin", isSecure: true, text: .constant(""))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 