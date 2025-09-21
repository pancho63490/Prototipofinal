import SwiftUI

struct PrintingView: View {
    // Propiedades enlazadas
    @Binding var useCustomLabels: Bool
    @Binding var customLabels: Int

    // Formatter para valores enteros sin decimales
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Encabezado destacado
            Text("Print Labels")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Contenedor de campos en un HStack para simular una fila
            HStack(spacing: 12) {
                // Etiqueta que varía según useCustomLabels
                Text(useCustomLabels ? "Custom Quantity:" : "Default Quantity:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                
                TextField("Enter quantity", value: $customLabels, formatter: numberFormatter)
                    .keyboardType(.numberPad)
                    .padding(8)
                    .frame(width: 100)
                    .background(Color.white)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            
            
         Text("Select a quantity to print your custom labels")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
        .overlay(
            Toggle("", isOn: $useCustomLabels)
                .hidden()
        )
    }
}

struct PrintingView_Previews: PreviewProvider {
    static var previews: some View {
        PrintingView(useCustomLabels: .constant(true), customLabels: .constant(1))
            .preferredColorScheme(.light)
    }
}
