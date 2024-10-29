import Foundation
import ExternalAccessory

class PrintViewController {
    var connectedAccessories: [EAAccessory] = []
    
    // Iniciar el proceso de impresión
    func startPrinting(trackingNumber: String, invoiceNumber: String, palletNumber: Int, objectID: String, completion: @escaping (Bool, Error?) -> Void) {
        updateConnectedAccessories()
        
        guard let accessory = connectedAccessories.first(where: { $0.modelNumber.hasPrefix("ZQ630") }) else {
            completion(true, nil)
            return
        }
        
        print("Conectando con impresora: \(accessory.name)")
        connectToPrinter(eaAccessory: accessory) { connection, error in
            guard let connection = connection else {
                completion(false, error)
                return
            }
            
            // Imprimir la etiqueta
            self.printLabel(trackingNumber: trackingNumber,
                            invoiceNumber: invoiceNumber,
                            objectNumber: palletNumber,  // Cambia 'palletNumber' a 'objectNumber'
                            objectID: objectID,
                            connection: connection)

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
    func printLabel(trackingNumber: String, invoiceNumber: String, objectNumber: Int, objectID: String, connection: ZebraPrinterConnection) {
        // Calibrar la impresora para medios con marcas negras
        let calibrationZPL = "^XA^JU^XZ"
        if let calibrationData = calibrationZPL.data(using: .utf8) {
            connection.write(calibrationData, error: nil)
            print("Calibración de la impresora realizada.")
        }

        let currentDateTime = getCurrentDateTime()
        let labelZPL = """
        ^XA
        ^MMT
        ^PW812
        ^LL1218
        ^LS0
        ^MNM

        // Título de la etiqueta
        ^FT50,100^A0N,60,60^FH\\^FDB O S C H  -  X  D O C K^FS
        ^FO40,120^GB732,0,4^FS // Línea horizontal debajo del título

        // Tracking Number
        ^FT50,200^A0N,40,40^FH\\^FDTracking Number:^FS
        ^FT50,240^A0N,40,40^FH\\^FD\(trackingNumber)^FS
        ^BY3,3,100^FT50,350^BCN,,Y,N
        ^FD>:\(trackingNumber)^FS // Código de barras para Tracking Number

        // Object Number
        ^FT50,480^A0N,40,40^FH\\^FDObject Number: \(objectNumber)^FS

        // Object ID
        ^FT50,520^A0N,40,40^FH\\^FDObject ID: \(objectID)^FS
        ^BY3,3,100^FT50,630^BCN,,Y,N
        ^FD>:\(objectID)^FS // Código de barras para Object ID

        // Fecha y Hora de llegada
        ^FT50,760^A0N,40,40^FH\\^FDDate Time: \(currentDateTime)^FS

        ^PQ1,0,1,Y
        ^XZ
        """

        guard let data = labelZPL.data(using: .utf8) else {
            print("Error: No se pudo convertir el ZPL a datos.")
            return
        }

        connection.write(data, error: nil)
        print("Etiqueta del object \(objectNumber) enviada con ObjectID: \(objectID).")
    }

    // Función auxiliar para obtener la fecha y hora actuales
    func getCurrentDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }



    // Cerrar la conexión con la impresora
    func closePrinterConnection(connection: ZebraPrinterConnection) {
        connection.close()
        print("Conexión con la impresora cerrada.")
    }
}
