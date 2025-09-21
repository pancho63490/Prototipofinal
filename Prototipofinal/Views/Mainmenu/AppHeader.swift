import SwiftUI

struct AppHeader: View {
    var body: some View {
        VStack(spacing: 4) {
            
            Image(systemName: "shippingbox.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.white)

    
            Text("XDOCK")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("NixiScan")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))

            Text("Efficient Shipping Solutions")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.40, blue: 1.0),   // Azul
                    Color(red: 0.55, green: 0.15, blue: 0.68)  // Morado
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
}

struct AppHeader_Previews: PreviewProvider {
    static var previews: some View {
        AppHeader()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
    }
}
