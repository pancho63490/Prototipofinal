import SwiftUI

// Modelo de Material
struct Material: Identifiable {
    let id = UUID()
    let reference: String
    let quantity: Int
    let unit: String
}

struct MaterialListView: View {
    @State private var materials: [Material] = []
    var trackingData: [TrackingData]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                // Título, ahora más pequeño (title3) y semibold en lugar de .title
                Text("Material List")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                
                // Si no hay materiales
                if materials.isEmpty {
                    Text("No materials available")
                        .font(.footnote)       // Más pequeño que .subheadline
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Para cada material, mostramos una fila “tipo tarjeta”
                    ForEach(materials) { material in
                        HStack(spacing: 8) {
                            // Ícono principal
                            Image(systemName: "cube.box")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Más pequeño que antes
                                .foregroundColor(.blue)
                            
                            // Columnas de texto
                            VStack(alignment: .leading, spacing: 2) {
                                // Referencia (subheadline un poco más grande que footnote)
                                Text(material.reference)
                                    .font(.subheadline)
                                
                                HStack {
                                    Image(systemName: "number.circle")
                                        .foregroundColor(.green)
                                    // Cantidad con fuente aún más pequeña (caption)
                                    Text("\(material.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Image(systemName: "scalemass")
                                        .foregroundColor(.orange)
                                    // Unidad también en caption
                                    Text(material.unit)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal, 8)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemGray6))
        .onAppear {
            loadMaterials()
        }
    }
    
    // Carga la información proveniente de TrackingData en el modelo local 'materials'
    func loadMaterials() {
        materials = trackingData.map { data in
            Material(
                reference: data.material,
                quantity: Int(data.deliveryQty) ?? 0,
                unit: data.unit ?? "Nil"
            )
        }
    }
}
