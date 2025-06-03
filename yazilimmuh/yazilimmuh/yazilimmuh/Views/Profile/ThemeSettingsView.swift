import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTheme: ThemeManager.Theme
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "userTheme")
        if let savedTheme = savedTheme,
           let theme = ThemeManager.Theme(rawValue: savedTheme) {
            _selectedTheme = State(initialValue: theme)
        } else {
            _selectedTheme = State(initialValue: .system)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Görünüm")) {
                    Picker("Tema", selection: $selectedTheme) {
                        Label("Açık", systemImage: "sun.max.fill")
                            .tag(ThemeManager.Theme.light)
                        
                        Label("Koyu", systemImage: "moon.fill")
                            .tag(ThemeManager.Theme.dark)
                        
                        Label("Sistem", systemImage: "gear")
                            .tag(ThemeManager.Theme.system)
                    }
                    .pickerStyle(.inline)
                    .onChange(of: selectedTheme) { newValue in
                        themeManager.theme = newValue
                    }
                }
                
                Section(header: Text("Hakkında"), footer: Text("Koyu temayı etkinleştirdiğinizde, uygulama koyu arka plan ve açık renk metin kullanır. Bu göz yorgunluğunu azaltabilir ve düşük ışıklı ortamlarda okumayı kolaylaştırabilir.")) {
                    HStack {
                        Image(systemName: "moon.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading) {
                            Text("Koyu Tema")
                                .font(.headline)
                            Text("Göz yorgunluğunu azaltın")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Tema Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ThemeSettingsView()
        .environmentObject(ThemeManager())
} 
 