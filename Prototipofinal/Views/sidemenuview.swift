import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedView: String?

    var body: some View {
        ZStack {
            // Capa semitransparente para oscurecer el contenido principal.
            if isMenuOpen {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen.toggle()
                        }
                    }
            }
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 100)
                    
                    // Botón para Main View
                    Button("Main View") {
                        withAnimation {
                            selectedView = "main"
                            isMenuOpen.toggle()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    // Botón para Report View
                    Button("Report View") {
                        withAnimation {
                            selectedView = "report"
                            isMenuOpen.toggle()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    // Botón para Material Unknown
                    Button("Material Unknown") {
                        withAnimation {
                            selectedView = "materialUnknown"
                            isMenuOpen.toggle()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    // Botón para Insert Tooling
                    Button("Insert Tooling") {
                        withAnimation {
                            selectedView = "insertTooling"
                            isMenuOpen.toggle()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(width: UIScreen.main.bounds.width * 0.35)
                // Usamos el color del sistema para mayor coherencia minimalista
                .background(Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.all)
                // El desplazamiento del menú depende de su estado
                .offset(x: isMenuOpen ? 0 : -UIScreen.main.bounds.width * 0.35)
                .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
                
                Spacer()
            }
        }
    }
}
