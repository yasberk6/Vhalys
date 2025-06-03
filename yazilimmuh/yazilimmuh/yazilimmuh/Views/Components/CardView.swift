import SwiftUI

// Standart kart tasarımı
struct CardView<Content: View>: View {
    var content: Content
    var backgroundColor: Color = .white
    var shadowRadius: CGFloat = 8
    var cornerRadius: CGFloat = 16
    
    init(
        backgroundColor: Color = .white,
        shadowRadius: CGFloat = 8,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: shadowRadius,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// Gradient arkaplan rengiyle kart tasarımı
struct GradientCardView<Content: View>: View {
    var content: Content
    var colors: [Color]
    var cornerRadius: CGFloat = 16
    
    init(
        colors: [Color] = [.themePrimary.opacity(0.8), .themePrimary],
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.colors = colors
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: colors.first?.opacity(0.3) ?? Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// Daha modern, hafif gölgeli kart
struct ModernCardView<Content: View>: View {
    var content: Content
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    
    init(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
    }
}

// Önizleme
struct CardViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CardView {
                Text("Standart Kart")
                    .font(.headline)
                    .padding()
            }
            
            GradientCardView {
                Text("Gradient Kart")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
            
            ModernCardView {
                Text("Modern Kart")
                    .font(.headline)
                    .padding()
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 