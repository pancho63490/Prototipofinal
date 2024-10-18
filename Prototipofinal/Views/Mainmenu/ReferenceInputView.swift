import SwiftUI

struct ReferenceInputView: View {
    @Binding var referenceNumber: String
    @Binding var isScanning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("Número de referencia", text: $referenceNumber)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    Button(action: {
                        isScanning = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.blue)
                            .padding(.trailing)
                    },
                    alignment: .trailing
                )
        }
    }
}
