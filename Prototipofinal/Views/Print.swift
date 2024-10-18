import SwiftUI

struct PrintView: View {
    var referenceNumber: String
    var trackingData: [TrackingData]
    var customLabels: Int
    var useCustomLabels: Bool
    @State private var shouldDismiss = false // Estado para manejar la navegación automática

    @Environment(\.presentationMode) var presentationMode // Controla la navegación hacia atrás
    @Binding var finalObjectIDs: [String] // Para pasar los Object IDs generados a la vista principal

    @State private var isPrintingComplete = false
    @State private var currentPallet = 1
    @State private var errorMessage = ""
    @State private var objectIDs: [String] = [] // Arreglo para almacenar los Object IDs como cadenas

    var body: some View {
        VStack {
            Text("Impresión en Proceso")
                .font(.title)
                .padding()

            if !isPrintingComplete {
                ProgressView("Imprimiendo \(currentPallet) de \(useCustomLabels ? customLabels : distinctMaterialCount()) etiquetas...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Text("Impresión completada")
                    .foregroundColor(.green)
                    .font(.headline)
                    .padding()
            }

            if !errorMessage.isEmpty {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            requestObjectIDsAndStartPrintProcess()
        }
        .onChange(of: isPrintingComplete) { complete in
            if complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Espera 2 segundos antes de regresar automáticamente
                    self.finalObjectIDs = objectIDs // Pasamos los object IDs generados
                    self.presentationMode.wrappedValue.dismiss() // Regresar automáticamente al menú principal
                }
            }
        }
    }

    // Función para contar el número de materiales distintos en trackingData
    func distinctMaterialCount() -> Int {
        let uniqueMaterials = Set(trackingData.map { $0.material })
        return uniqueMaterials.count
    }

    // Función para solicitar Object IDs a la API y luego iniciar el proceso de impresión
    func requestObjectIDsAndStartPrintProcess() {
        let totalLabels = useCustomLabels ? customLabels : distinctMaterialCount()
        guard let firstTrackingData = trackingData.first else {
            self.errorMessage = "No hay datos de seguimiento disponibles."
            return
        }

        let requestData = [
            "REF_NUM": firstTrackingData.externalDeliveryID,
            "QTY": totalLabels
        ] as [String : Any]

        APIServiceobj().requestObjectIDs(requestData: requestData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let objectIDResponse):
                    guard !objectIDResponse.objectIDs.isEmpty else {
                        self.errorMessage = "No se obtuvieron Object IDs de la API."
                        return
                    }
                    self.objectIDs = objectIDResponse.objectIDs.map { String($0) }
                    self.startPrintProcess() // Inicia la impresión después de obtener los Object IDs
                case .failure(let error):
                    self.errorMessage = "Error al obtener Object IDs: \(error.localizedDescription)"
                }
            }
        }
    }

    // Función para iniciar el proceso de impresión después de obtener los Object IDs
    func startPrintProcess() {
        currentPallet = 1
        let printController = PrintViewController()
        printNextPallet(printController: printController)
    }

    // Función para imprimir cada etiqueta utilizando los Object IDs
    func printNextPallet(printController: PrintViewController) {
        let totalLabels = useCustomLabels ? customLabels : distinctMaterialCount()

        guard currentPallet <= totalLabels else {
            isPrintingComplete = true
            return
        }

        guard !objectIDs.isEmpty else {
            self.errorMessage = "No hay Object IDs disponibles para imprimir."
            return
        }

        let objectID = useCustomLabels || currentPallet > objectIDs.count ? "CustomLabel-\(currentPallet)" : objectIDs[currentPallet - 1]

        printController.startPrinting(trackingNumber: referenceNumber,
                                      invoiceNumber: referenceNumber,
                                      palletNumber: currentPallet,
                                      objectID: objectID) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("Etiqueta \(self.currentPallet) impresa con ObjectID: \(objectID)")
                    self.currentPallet += 1
                    self.printNextPallet(printController: printController) // Continuar con la siguiente etiqueta
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
