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
        NavigationView {
            List {
                if materials.isEmpty {
                    Text("No materials available")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                      
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(materials) { material in
                        HStack(spacing: 17) {
                            // Ícono principal con fondo y forma redondeada
                            Image(systemName: "cube.box")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                                .padding(5)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            VStack(alignment: .leading, spacing: 6) {
                            
                                Text(material.reference)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 10) {
                                    // Cantidad
                                    HStack(spacing: 4) {
                                        Image(systemName: "number.circle")
                                            .foregroundColor(.green)
                                        Text("\(material.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    // Unidad
                                    HStack(spacing: 10) {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(.orange)
                                        Text(material.unit)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            Spacer()
                        }
                        // Se utiliza un padding vertical moderado
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        // Se aplican insets para dar un espacio moderado entre filas
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Material List", displayMode: .inline)
            .onAppear {
                loadMaterials()
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
    
    
    func loadMaterials() {
        materials = trackingData.map { data in
            Material(
                reference: data.material,
                quantity: Int(data.deliveryQty) ?? 0,
                unit: data.unit ?? "N/A"
            )
        }
    }
}


struct MaterialListView_Previews: PreviewProvider {
  
    struct DummyTrackingData: Identifiable {
        let id = UUID()
        let material: String
        let deliveryQty: String
        let unit: String?
    }
    
    static var previews: some View {
        let dummyData = [
            DummyTrackingData(material: "Aluminio", deliveryQty: "20", unit: "kg"),
            DummyTrackingData(material: "Madera", deliveryQty: "15", unit: "pcs")
        ]
        
    
        MaterialListView(trackingData: dummyData as! [TrackingData])
    }
}
