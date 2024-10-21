import SwiftUI

struct ExportView: View {
    @State private var truckData: [Truck] = [] // Datos de camiones
    @State private var scannedObjectIDs: Set<String> = [] // Registro de objectIDs escaneados
    @State private var isLoading = false // Indicador de carga
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showScannerView = false // Control del escáner
    @State private var currentObjectID: String? // ObjectID en proceso de escaneo
    @State private var isScanning = false // Control del escaneo activo

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Cargando datos...")
                    } else {
                        List(truckData, id: \.id) { truck in
                            Section(header: Text("Camión: \(truck.deliveryType)").font(.headline)) {
                                ForEach(truck.uniqueObjectIDs, id: \.self) { objectID in
                                    HStack {
                                        Text("Object ID: \(objectID)")
                                        Spacer()
                                        if scannedObjectIDs.contains(objectID) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Button(action: {
                                                currentObjectID = objectID
                                                isScanning = true
                                            }) {
                                                Image(systemName: "barcode.viewfinder")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                                if allObjectsScanned(for: truck) {
                                    Button(action: {
                                        markTruckAsCompleted(truck)
                                    }) {
                                        Text("Enviar y Recargar")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .padding(.top, 10)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .onAppear(perform: fetchTruckData)
                .navigationTitle("Exportación")
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("Aceptar")))
                }
                if isScanning {
                    ZStack {
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)
                        CameraScannerView(scannedCode: .constant(nil)) { code in
                            validateScannedObjectID(code)
                            isScanning = false
                        }
                        .edgesIgnoringSafeArea(.all)
                        Rectangle()
                            .stroke(Color.green, lineWidth: 4)
                            .frame(width: 350, height: 150)
                            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 175)
                        VStack {
                            Spacer()
                            Button(action: {
                                isScanning = false
                            }) {
                                Text("Cancelar")
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
        }
    }

    // Lógica para cargar datos desde la API
    func fetchTruckData() {
        isLoading = true
        let urlString = "https://run.mocky.io/v3/bc0249e8-c5a3-435a-883c-befce790f5c8"

        guard let url = URL(string: urlString) else {
            showError(message: "URL inválida.")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    showError(message: "Error al obtener datos: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    showError(message: "Datos no válidos.")
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode([Truck].self, from: data)
                    truckData = decodedData
                    print("Datos decodificados correctamente: \(truckData)")
                } catch let decodingError {
                    showError(message: "Error al decodificar los datos: \(decodingError.localizedDescription)")
                    print("Detalles del error: \(decodingError)")
                }
            }
        }
        task.resume()
    }

    // Validar si el código escaneado coincide con el Object ID
    func validateScannedObjectID(_ scannedCode: String?) {
        guard let code = scannedCode?.trimmingCharacters(in: .whitespacesAndNewlines),
              let objectID = currentObjectID?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("Código o ObjectID no válido.")
            return
        }

        // Mostrar en la consola ambos valores para comparar
        print("Código escaneado: '\(code)'")
        print("ObjectID esperado: '\(objectID)'")

        if code == objectID {
            scannedObjectIDs.insert(objectID)
            print("Escaneado correctamente: \(objectID)")
        } else {
            showError(message: "El código escaneado no coincide con el Object ID.")
            print("Error: Los códigos no coinciden.")
        }
    }

    // Verificar si todos los objetos del camión han sido escaneados
    func allObjectsScanned(for truck: Truck) -> Bool {
        truck.uniqueObjectIDs.allSatisfy { scannedObjectIDs.contains($0) }
    }

    func markTruckAsCompleted(_ truck: Truck) {
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/TrukData/UpdateBill"

        guard let url = URL(string: urlString) else {
            showError(message: "URL inválida.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Cuerpo de la solicitud con el formato correcto
        let body: [String: Any] = [
            "DeliveryType": truck.deliveryType
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            showError(message: "Error al codificar los datos: \(error.localizedDescription)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError(message: "Error al enviar datos: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    showError(message: "Respuesta no válida del servidor.")
                    return
                }

                if httpResponse.statusCode == 200 {
                    print("Datos enviados correctamente. Camión: \(truck.deliveryType)")
                    fetchTruckData() // Recargar los datos después del éxito
                } else {
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("Error en la respuesta del servidor: \(responseBody)")
                        showError(message: "Error en el servidor: \(responseBody)")
                    } else {
                        showError(message: "Error desconocido en el servidor.")
                    }
                }
            }
        }
        task.resume()
    }



    // Mostrar error en alerta
    func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

// Modelo de datos para camiones
struct Truck: Codable, Identifiable {
    let id = UUID()
    let deliveryType: String
    let objectIDs: [String]

    // Computed property para eliminar duplicados
    var uniqueObjectIDs: [String] {
        Array(Set(objectIDs))
    }

    enum CodingKeys: String, CodingKey {
        case deliveryType = "DeliveryType"
        case objectIDs = "ObjectIDs"
    }
}

// Vista previa para Xcode
struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
