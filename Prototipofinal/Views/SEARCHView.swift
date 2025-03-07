import SwiftUI

// MARK: - Modelos para decodificar la respuesta JSON

struct DeliveryResponse2: Codable {
    let data: [Delivery]
}

struct Delivery: Codable, Identifiable {
    var id: String { EXTERNAL_DELVRY_ID }
    let EXTERNAL_DELVRY_ID: String
    let MATERIAL: String
    let DELIVERY_QTY: String
    let SUPPLIER_NAME: String
    let SRC: String
}

// MARK: - Vista Principal

struct DeliverySearchView: View {
    @State private var searchText = ""
    @State private var deliveries: [Delivery] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Buscador
                HStack {
                    TextField("Buscar...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        fetchDeliveries()
                    }) {
                        Text("Buscar")
                    }
                }
                .padding()
                
                // Indicador de carga o mensaje de error
                if isLoading {
                    ProgressView("Cargando...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Lista de resultados
                List(deliveries) { delivery in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("External Delivery: \(delivery.EXTERNAL_DELVRY_ID)")
                            .fontWeight(.bold)
                        Text("Material: \(delivery.MATERIAL)")
                        Text("Cantidad: \(delivery.DELIVERY_QTY)")
                        Text("Supplier: \(delivery.SUPPLIER_NAME)")
                        Text("SRC: \(delivery.SRC)")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Buscador de Entregas")
        }
    }
    
    // MARK: - Función para hacer la petición PUT
    func fetchDeliveries() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            deliveries = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/updatefiles") else {
            errorMessage = "URL inválida"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["Search": searchText]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Error en la respuesta del servidor."
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No se recibieron datos."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(DeliveryResponse2.self, from: data)
                    deliveries = responseData.data
                } catch {
                    errorMessage = "Error al decodificar la respuesta: \(error.localizedDescription)"
                    print("Datos recibidos: \(String(data: data, encoding: .utf8) ?? "Formato incorrecto")")
                }
            }
        }.resume()
    }
}

// MARK: - Vista de Previsualización

struct DeliverySearchView_Previews: PreviewProvider {
    static var previews: some View {
        DeliverySearchView()
    }
}
