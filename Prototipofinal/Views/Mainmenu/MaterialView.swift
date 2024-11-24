import SwiftUI

// Modelo de Material
struct Material: Identifiable {
    let id = UUID() // Identificador único para SwiftUI
    let reference: String
    let quantity: Int
    let unit: String
}

struct MaterialListView: View {
    @State private var materials: [Material] = []
    
    var trackingData: [TrackingData] // Datos que provienen de la API
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) { // Reducido el spacing
                Text("Material List")
                    .font(.headline)
                    .padding([.top, .leading, .trailing], 8) // Reducido padding

                if materials.isEmpty {
                    Text("No materials available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(8) // Reducido padding
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(materials) { material in
                            HStack(alignment: .center) { // Cambiado alignment a center
                                // Ícono de referencia
                                Image(systemName: "cube.box")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.blue)
                                
                                Text(material.reference)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .padding(.leading, 4)
                                
                                Spacer()
                                
                                // Ícono de cantidad
                                HStack(spacing: 2) {
                                    Image(systemName: "number.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.green)
                                    
                                    Text("\(material.quantity)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 8)
                                
                                // Ícono de unidad
                                HStack(spacing: 2) {
                                    Image(systemName: "scalemass")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.orange)
                                    
                                    Text(material.unit)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4) // Reducido padding vertical
                            .contentShape(Rectangle()) // Mejora la interacción
                        }
                    }
                    .listStyle(PlainListStyle()) // Mantener estilo plano
                    .frame(height: geometry.size.height) // Asegurar que la lista ocupe el espacio disponible
                }
            }
            .padding(.bottom, 4) // Reducido padding inferior
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadMaterials() // Cargar materiales desde trackingData
        }
    }

    // Función para mapear los datos de TrackingData a Material
    func loadMaterials() {
        materials = trackingData.map { data in
            Material(reference: data.material, quantity: Int(data.deliveryQty) ?? 0, unit: data.unit ?? "Nil")
        }
    }
}
