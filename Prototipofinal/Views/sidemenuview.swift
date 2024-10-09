import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedView: String?

    var body: some View {
        ZStack {
            // Fondo que oscurece el contenido principal cuando el menú está abierto
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen.toggle() // Cerrar el menú al tocar fuera
                        }
                    }
            }

            // Menú lateral
            HStack {
                VStack(alignment: .leading) {
                    Button(action: {
                        withAnimation {
                            selectedView = "main"
                            isMenuOpen.toggle() // Ir a la Main View
                        }
                    }) {
                        Text("Main View")
                            .font(.headline)
                            .foregroundColor(.blue) // Texto en azul
                            .padding(.top, 100)
                            .padding(.leading, 20)
                    }

                    Button(action: {
                        withAnimation {
                            selectedView = "report"
                            isMenuOpen.toggle() // Ir a la Report View
                        }
                    }) {
                        Text("Report View")
                            .font(.headline)
                            .foregroundColor(.blue) // Texto en azul
                            .padding(.top, 20)
                            .padding(.leading, 20)
                    }

                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.35) // Ahora ocupa un 35% de la pantalla
                .background(Color.white) // Fondo blanco para el menú
                .edgesIgnoringSafeArea(.all)
                .offset(x: isMenuOpen ? 0 : -UIScreen.main.bounds.width * 0.35) // Oculto cuando está cerrado
                .animation(.easeInOut(duration: 0.3), value: isMenuOpen)

                Spacer()
            }
        }
    }
}
