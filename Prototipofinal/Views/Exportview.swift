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
                        List(truckData, id: \.truckNumber) { truck in
                            Section(header: Text("Camión: \(truck.truckNumber)").font(.headline)) {
                                ForEach(truck.objectIDs, id: \.self) { objectID in
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
                                
                                // Botón para marcar como completado y ejecutar la API
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

                        // Zona de interés con recuadro verde
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

    // Lógica para cargar datos desde la API de Mocky
    func fetchTruckData() {
        isLoading = true
        let urlString = "https://run.mocky.io/v3/37a9fc08-5679-4bbe-b0c1-c2de9f9f2a30"

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
                } catch {
                    showError(message: "Error al decodificar los datos.")
                }
            }
        }
        task.resume()
    }

    // Validar si el código escaneado coincide con el Object ID
    func validateScannedObjectID(_ scannedCode: String?) {
        guard let code = scannedCode, let objectID = currentObjectID else { return }

        if code == objectID {
            scannedObjectIDs.insert(objectID)
            print("Escaneado correctamente: \(objectID)")
        } else {
            showError(message: "El código escaneado no coincide con el Object ID.")
        }
    }

    // Verificar si todos los objetos del camión han sido escaneados
    func allObjectsScanned(for truck: Truck) -> Bool {
        truck.objectIDs.allSatisfy { scannedObjectIDs.contains($0) }
    }

    // Marcar camión como completado y llamar a la API
    func markTruckAsCompleted(_ truck: Truck) {
        let urlString = "https://run.mocky.io/v3/37a9fc08-5679-4bbe-b0c1-c2de9f9f2a30" // API para completar

        guard let url = URL(string: urlString) else {
            showError(message: "URL inválida.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "truckNumber": truck.truckNumber,
            "objectIDs": Array(scannedObjectIDs)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            showError(message: "Error al codificar los datos.")
            return
        }
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError(message: "Error al enviar datos: \(error.localizedDescription)")
                    return
                }
                print("Datos enviados correctamente.")
                fetchTruckData() // Recargar la vista
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

// Modelo de datos para camión y objectIDs
struct Truck: Codable, Identifiable {
    let id = UUID()
    let truckNumber: String
    let objectIDs: [String]
}

// Preview para probar la vista en Xcode
struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
