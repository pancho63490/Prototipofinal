import SwiftUI

// Modelo de Material
struct Material: Identifiable {
    let id = UUID() // Identificador único para SwiftUI
    let reference: String
    let quantity: Int
}

struct MaterialListView: View {
    @State private var materials: [Material] = []

    var trackingData: [TrackingData] // Datos que provienen de la API

    var body: some View {
        VStack(alignment: .leading) {
            Text("Lista de Materiales")
                .font(.headline)
                .padding()

            if materials.isEmpty {
                Text("No hay materiales disponibles.")
                    .padding()
            } else {
                List(materials) { material in
                    HStack {
                        Text(material.reference)
                        Spacer()
                        Text("Cantidad: \(material.quantity)")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            loadMaterials() // Cargar materiales desde trackingData
        }
    }

    // Función para mapear los datos de TrackingData a Material
    func loadMaterials() {
        materials = trackingData.map { data in
            Material(reference: data.material, quantity: Int(data.deliveryQty) ?? 0)
        }
    }
}

// Preview para el diseño
struct MaterialListView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialListView(trackingData: [
            TrackingData(externalDeliveryID: "QE241004IN-SDS", material: "Material 1", deliveryQty: "10", deliveryNo: "1814648917", supplierVendor: "0097216287", supplierName: "Supplier A", container: "", src: ""),
            TrackingData(externalDeliveryID: "QE241004IN-SDS", material: "Material 2", deliveryQty: "5", deliveryNo: "1814648917", supplierVendor: "0097216287", supplierName: "Supplier B", container: "", src: "")
        ])
    }
}
