import Foundation
import ExternalAccessory

class PrintViewController {
    var connectedAccessories: [EAAccessory] = []
    
    // Iniciar el proceso de impresión
    func startPrinting(trackingNumber: String, invoiceNumber: String, palletNumber: Int, objectID: String, completion: @escaping (Bool, Error?) -> Void) {
        updateConnectedAccessories()
        
        guard let accessory = connectedAccessories.first(where: { $0.modelNumber.hasPrefix("ZQ630") }) else {
            completion(false, NSError(domain: "Impresora no encontrada", code: 404, userInfo: nil))
            return
        }
        
        print("Conectando con impresora: \(accessory.name)")
        connectToPrinter(eaAccessory: accessory) { connection, error in
            guard let connection = connection else {
                completion(false, error)
                return
            }
            
            // Imprimir la etiqueta
            self.printLabel(trackingNumber: trackingNumber, invoiceNumber: invoiceNumber, palletNumber: palletNumber, objectID: objectID, connection: connection)
            
            self.closePrinterConnection(connection: connection)
            completion(true, nil)
        }
    }
    
    // Actualizar lista de impresoras conectadas
    func updateConnectedAccessories() {
        connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        print("Accesorios detectados: \(connectedAccessories.count)")
    }
    
    // Conectar a la impresora Zebra
    func connectToPrinter(eaAccessory: EAAccessory, completion: @escaping (ZebraPrinterConnection?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let connection = MfiBtPrinterConnection(serialNumber: eaAccessory.serialNumber) else {
                completion(nil, NSError(domain: "Error al crear la conexión", code: 500, userInfo: nil))
                return
            }
            
            if connection.open() {
                completion(connection, nil)
            } else {
                completion(nil, NSError(domain: "No se pudo abrir la conexión", code: 500, userInfo: nil))
            }
        }
    }
    
    // Imprimir una etiqueta
    func printLabel(trackingNumber: String, invoiceNumber: String, palletNumber: Int, objectID: String, connection: ZebraPrinterConnection) {
        let labelZPL = """
        ^XA
        ^PW812      // Ancho de la etiqueta de 4 pulgadas
        ^LL609      // Largo de la etiqueta de 3 pulgadas
        ^FO50,50^A0,50,50^FDTracking: \(trackingNumber)^FS
        ^FO50,150^A0,50,50^FDInvoice: \(invoiceNumber)^FS
        ^FO50,250^A0,50,50^FDPallet: \(palletNumber)^FS
        ^FO50,350^A0,50,50^FDObjectID: \(objectID)^FS
        ^XZ
        """
        
        let data = labelZPL.data(using: .utf8)!
        connection.write(data, error: nil)
        print("Etiqueta del pallet \(palletNumber) enviada con ObjectID: \(objectID).")
    }
    
    // Cerrar la conexión con la impresora
    func closePrinterConnection(connection: ZebraPrinterConnection) {
        connection.close()
        print("Conexión con la impresora cerrada.")
    }
}
