import SwiftUI

struct AppHeader: View {
    var body: some View {
        VStack {
            Image(systemName: "shippingbox.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            
            Text("XDOCK")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.top, 40)
    }
}
