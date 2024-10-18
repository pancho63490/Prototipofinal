import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/Exportview.swift", line: 1)
import SwiftUI

struct ExportView: View {
    @State private var truckData: [Truck] = [] // Datos de camiones
    @State private var scannedObjectIDs: Set<String> = [] // Registro de objectIDs escaneados
    @State private var isLoading = false // Indicador de carga
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showScannerView = false // Control del scanner
    @State private var currentObjectID: String? // ObjectID que se escaneará

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView(__designTimeString("#8528_0", fallback: "Cargando datos..."))
                } else {
                    List(truckData, id: \.truckNumber) { truck in
                        Section(header: Text("Camión: \(truck.truckNumber)").font(.headline)) {
                            ForEach(truck.objectIDs, id: \.self) { objectID in
                                HStack {
                                    Text("Object ID: \(objectID)")
                                    Spacer()
                                    if scannedObjectIDs.contains(objectID) {
                                        Image(systemName: __designTimeString("#8528_1", fallback: "checkmark.circle.fill"))
                                            .foregroundColor(.green)
                                    } else {
                                        Button(action: {
                                            currentObjectID = objectID
                                            showScannerView = __designTimeBoolean("#8528_2", fallback: true)
                                        }) {
                                            Image(systemName: __designTimeString("#8528_3", fallback: "barcode.viewfinder"))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(.vertical, __designTimeInteger("#8528_4", fallback: 5))
                            }

                            if allObjectsScanned(for: truck) {
                                Button(action: {
                                    markTruckAsCompleted(truck)
                                }) {
                                    Text(__designTimeString("#8528_5", fallback: "Marcar como Completado"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(__designTimeInteger("#8528_6", fallback: 10))
                                }
                                .padding(.top, __designTimeInteger("#8528_7", fallback: 10))
                            }
                        }
                    }
                }
                Spacer()
            }
            .onAppear(perform: fetchTruckData)
            .navigationTitle(__designTimeString("#8528_8", fallback: "Exportación"))
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text(__designTimeString("#8528_9", fallback: "Error")), message: Text(errorMessage), dismissButton: .default(Text(__designTimeString("#8528_10", fallback: "Aceptar"))))
            }
            .sheet(isPresented: $showScannerView) {
                if let objectID = currentObjectID {
                    CameraScannerWrapperView(scannedCode: .constant(nil)) { scannedCode in
                        validateScannedObjectID(scannedCode, expectedID: objectID)
                    }
                }
            }
        }
    }

    func fetchTruckData() {
        isLoading = __designTimeBoolean("#8528_11", fallback: true)
        let urlString = __designTimeString("#8528_12", fallback: "https://mocky.io/v3/tu-endpoint-unico") // Coloca aquí tu URL de Mocky

        guard let url = URL(string: urlString) else {
            showError(message: __designTimeString("#8528_13", fallback: "URL inválida."))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = __designTimeBoolean("#8528_14", fallback: false)

                if let error = error {
                    showError(message: "Error al obtener datos: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    showError(message: __designTimeString("#8528_15", fallback: "Datos no válidos."))
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode([Truck].self, from: data)
                    truckData = decodedData
                } catch {
                    showError(message: __designTimeString("#8528_16", fallback: "Error al decodificar los datos."))
                }
            }
        }
        task.resume()
    }

    func validateScannedObjectID(_ scannedCode: String?, expectedID: String) {
        guard let code = scannedCode, code == expectedID else {
            showError(message: __designTimeString("#8528_17", fallback: "El código escaneado no coincide con el Object ID esperado."))
            return
        }
        scannedObjectIDs.insert(expectedID)
        print("Escaneado correctamente: \(expectedID)")
    }

    func allObjectsScanned(for truck: Truck) -> Bool {
        return truck.objectIDs.allSatisfy { scannedObjectIDs.contains($0) }
    }

    func markTruckAsCompleted(_ truck: Truck) {
        print("Camión \(truck.truckNumber) marcado como completado.")
        // Aquí podrías enviar la confirmación a una API si es necesario.
    }

    func showError(message: String) {
        errorMessage = message
        showErrorAlert = __designTimeBoolean("#8528_18", fallback: true)
    }
}

struct Truck: Codable, Identifiable {
    let id = UUID()
    let truckNumber: String
    let objectIDs: [String]
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
