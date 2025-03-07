import SwiftUI

struct AppHeader: View {
    @State private var isAnimating = false // Para animaciones opcionales
    
    var body: some View {
        VStack(spacing: 10) {
            // Icono Mejorado con Animación Opcional
            Image(systemName: "shippingbox.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60) // Tamaño reducido de 80x80 a 60x60
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .rotationEffect(.degrees(isAnimating ? 360 : 0)) // Animación de rotación
                .animation(Animation.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            // Título Mejorado
            Text("XDOCK")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            Text("NixiScan")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            // Subtítulo o Descripción
            Text("Efficient Shipping Solutions")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding([.horizontal, .top], 20)
    }
}

struct AppHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppHeader()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
            
            AppHeader()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
