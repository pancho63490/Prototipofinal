/*import SwiftUI
struct ObjectRowView: View {
    @Binding var objectInfo: ObjectInfo
    var onScanQuantity: (ScanMethod) -> Void
    var onScanLocation: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Object ID: \(objectInfo.objectID)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Material: \(objectInfo.material)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Cantidad Total: \(objectInfo.totalQuantity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()

                if objectInfo.totalQuantity > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
            }
            
            HStack {
                Text("Locación: \(objectInfo.location.isEmpty ? "No definida" : objectInfo.location)")
                    .font(.system(size: 14))
                    .foregroundColor(objectInfo.location.isEmpty ? .red : .green)
                
                Spacer()

                if objectInfo.location.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                }
            }

            // Botones de acción
            HStack {
                Button(action: {
                    onScanQuantity(.cameraScanner)
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                        Text("Escanear Cantidad")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    onScanLocation()
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                        Text("Escanear Locación")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
*/

