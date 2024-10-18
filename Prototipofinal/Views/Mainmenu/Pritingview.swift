import SwiftUI

struct PrintingView: View {
    @Binding var useCustomLabels: Bool
    @Binding var customLabels: Int

    var body: some View {
        VStack(alignment: .leading) {
            Text("Imprimir etiquetas")
                .font(.headline)

            Toggle("Usar etiquetas personalizadas", isOn: $useCustomLabels)
                .padding()

            if useCustomLabels {
                Stepper("Cantidad personalizada: \(customLabels)", value: $customLabels, in: 1...100)
                    .padding()
            } else {
                Stepper("Cantidad predeterminada: \(customLabels)", value: $customLabels, in: 1...100)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
