import SwiftUI

struct PrintingView: View {
    // Se mantiene la propiedad, por ejemplo, con valor inicial true
    @Binding var useCustomLabels: Bool
    @Binding var customLabels: Int

    // Formatter para valores enteros sin decimales
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Print Labels")
                .font(.headline)
            
            // Toggle que se oculta del usuario
            Toggle("Use Custom Labels", isOn: $useCustomLabels)
                .hidden() // El Toggle está presente en la vista pero no se muestra
            
            HStack {
                // Se muestra el texto según el valor de useCustomLabels
                if useCustomLabels {
                    Text("Custom Quantity:")
                } else {
                    Text("Default Quantity:")
                }
                
                // TextField para ingresar manualmente el número de etiquetas
                TextField("Enter quantity", value: $customLabels, formatter: numberFormatter)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PrintingView_Previews: PreviewProvider {
    static var previews: some View {
        // En la vista previa, se inicializa useCustomLabels en true para usar siempre custom
        PrintingView(useCustomLabels: .constant(true), customLabels: .constant(1))
    }
}
