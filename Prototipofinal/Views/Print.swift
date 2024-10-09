import SwiftUI

struct PrintView: View {
    var trackingNumber: String
    var invoiceNumber: String
    var pallets: String
    
    @State private var isPrintingComplete = false
    @State private var currentPallet = 1
    @State private var palletCount: Int = 0
    @State private var shouldNavigateToScan = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("Impresión en Proceso")
                .font(.title)
                .padding()
            
            if !isPrintingComplete {
                ProgressView("Imprimiendo \(currentPallet) de \(palletCount) pallets...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Text("Impresión completada")
                    .foregroundColor(.green)
                    .font(.headline)
                    .padding()
                
                NavigationLink(destination: ScanView(), isActive: $shouldNavigateToScan) {
                    EmptyView()
                }
            }
            
            if !errorMessage.isEmpty {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            startPrintProcess()
        }
    }
    
    // Función para iniciar el proceso de impresión
    func startPrintProcess() {
        guard let totalPallets = Int(pallets), totalPallets > 0 else {
            errorMessage = "Número de pallets no válido."
            return
        }
        
        palletCount = totalPallets
        currentPallet = 1
        
        let printController = PrintViewController()
        printNextPallet(printController: printController)
    }
    
    // Función para imprimir cada pallet con su ObjectID
    func printNextPallet(printController: PrintViewController) {
        guard currentPallet <= palletCount else {
            isPrintingComplete = true
            shouldNavigateToScan = true
            return
        }
        
        let objectID = generateShortUUID() // Generar ObjectID corto de 6 caracteres
        
        printController.startPrinting(trackingNumber: trackingNumber, invoiceNumber: invoiceNumber, palletNumber: currentPallet, objectID: objectID) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("Pallet \(self.currentPallet) impreso con ObjectID: \(objectID)")
                    self.currentPallet += 1
                    self.printNextPallet(printController: printController) // Continuar con el siguiente pallet
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func generateShortUUID(length: Int = 6) -> String {
        let uuid = UUID().uuidString // Genera un UUID
        let shortUUID = String(uuid.prefix(length)) // Toma los primeros `length` caracteres
        return shortUUID
    }
}
