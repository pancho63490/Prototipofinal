import SwiftUI

struct PrintingView: View {
    @Binding var useCustomLabels: Bool
    @Binding var customLabels: Int

    var body: some View {
        VStack(alignment: .leading) {
            Text("Print Labels")
                .font(.headline)

            Toggle("Use Custom Labels", isOn: $useCustomLabels)
                .padding()

            if useCustomLabels {
                Stepper("Custom Quantity: \(customLabels)", value: $customLabels, in: 1...100)
                    .padding()
            } else {
                Stepper("Default Quantity: \(customLabels)", value: $customLabels, in: 1...100)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
