import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/Mainmenu/MaterialView.swift", line: 1)
import SwiftUI

struct Material: Identifiable {
    let id = UUID()
    let reference: String
    let quantity: Int
}

struct MaterialListView: View {
    @State private var materials: [Material] = [
        Material(reference: "Material 1", quantity: 10),
        Material(reference: "Material 2", quantity: 5),
        Material(reference: "Material 3", quantity: 7)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text(__designTimeString("#3556_0", fallback: "Lista de Materiales"))
                .font(.headline)

            List(materials) { material in
                HStack {
                    Text(material.reference)
                    Spacer()
                    Text("Cantidad: \(material.quantity)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(__designTimeInteger("#3556_1", fallback: 10))
    }
}

struct MaterialListView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialListView()
    }
}
