import Foundation
import ExternalAccessory

class PrintViewController {
    var connectedAccessories: [EAAccessory] = []
    
    // Start the printing process
    func startPrinting(trackingNumber: String, invoiceNumber: String, palletNumber: Int, objectID: String, totalLabels: Int, completion: @escaping (Bool, Error?) -> Void) {
        print("Starting print for Object ID: \(objectID), Pallet Number: \(palletNumber)")
        updateConnectedAccessories()
        
        guard let accessory = connectedAccessories.first(where: { $0.modelNumber.hasPrefix("ZQ630") }) else {
            print("No Zebra printer found connected.")
            completion(false, NSError(domain: "Printer not connected", code: 404, userInfo: [NSLocalizedDescriptionKey: "No Zebra printer found connected."]))
            return
        }
        
        print("Connecting to printer: \(accessory.name)")
        connectToPrinter(eaAccessory: accessory) { connection, error in
            if let error = error {
                print("Error connecting to printer: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            guard let connection = connection else {
                print("Printer connection not established.")
                completion(false, NSError(domain: "Connection failed", code: 500, userInfo: nil))
                return
            }
            
            // Print the label
            self.printLabel(trackingNumber: trackingNumber,
                            invoiceNumber: invoiceNumber,
                            objectNumber: palletNumber,
                            totalLabels: totalLabels,
                            objectID: objectID,
                            connection: connection)
    
            self.closePrinterConnection(connection: connection)
            print("Label sent to printer for Object ID: \(objectID)")
            completion(true, nil)
        }
    }
    
    // Update the list of connected printers
    func updateConnectedAccessories() {
        connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        print("Detected accessories: \(connectedAccessories.count)")
        for accessory in connectedAccessories {
            print("Accessory: \(accessory.name), Model: \(accessory.modelNumber)")
        }
    }
    
    // Connect to the Zebra printer
    func connectToPrinter(eaAccessory: EAAccessory, completion: @escaping (ZebraPrinterConnection?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            print("Attempting to create MfiBtPrinterConnection for accessory with serial: \(eaAccessory.serialNumber)")
            guard let connection = MfiBtPrinterConnection(serialNumber: eaAccessory.serialNumber) else {
                print("Error: Could not create MfiBtPrinterConnection.")
                completion(nil, NSError(domain: "Connection Creation Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create connection with the printer."]))
                return
            }
            
            if connection.open() {
                print("Successfully opened connection with the printer.")
                completion(connection, nil)
            } else {
                print("Error: Could not open connection with the printer.")
                completion(nil, NSError(domain: "Connection Open Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not open connection with the printer."]))
            }
        }
    }
    
    func printLabel(trackingNumber: String, invoiceNumber: String, objectNumber: Int, totalLabels: Int, objectID: String, connection: ZebraPrinterConnection) {
        print("Preparing ZPL label for Object ID: \(objectID)")
        // Calibrate the printer for media with black marks
        let calibrationZPL = "^XA^JU^XZ"
        if let calibrationData = calibrationZPL.data(using: .utf8) {
            var writeError: NSError?
            connection.write(calibrationData, error: &writeError)
            if let error = writeError {
                print("Error writing calibration data: \(error.localizedDescription)")
                // Consider handling the error as needed
            } else {
                print("Printer calibration completed.")
            }
        }

        let currentDateTime = getCurrentDateTime()
        let labelZPL = """
        ^XA
        ^PR2
        ^MMT
        ^PW812
        ^LL1218
        ^LS0
        ^MNM

        ^FX Label Title
        ^FT50,100^A0N,60,60^FH\\^FDB O S C H  -  X  D O C K^FS
        ^FO40,120^GB732,0,4^FS ^FX Horizontal line below the title

        ^FX Tracking Number
        ^FT50,200^A0N,40,40^FH\\^FDTracking Number:^FS
        ^FT50,240^A0N,40,40^FH\\^FD\(trackingNumber)^FS
        ^BY3,3,100^FT50,350^BCN,,Y,N
        ^FD>:\(trackingNumber)^FS ^FX Barcode for Tracking Number

        ^FX Object Number
        ^FT50,480^A0N,40,40^FH\\^FDObject Number: \(objectNumber)/\(totalLabels)^FS

        ^FX Object ID
        ^FT50,520^A0N,40,40^FH\\^FDObject ID: \(objectID)^FS
        ^BY3,3,100^FT50,630^BCN,,Y,N
        ^FD>:\(objectID)^FS ^FX Barcode for Object ID

        ^FX Arrival Date and Time
        ^FT50,760^A0N,40,40^FH\\^FDDate: \(currentDateTime)^FS

        ^PQ1,0,1,Y
        ^XZ
        """

        guard let data = labelZPL.data(using: .utf8) else {
            print("Error: Could not convert ZPL to data.")
            return
        }

        var writeError: NSError?
        connection.write(data, error: &writeError)
        if let error = writeError {
            print("Error writing label data: \(error.localizedDescription)")
        } else {
            print("Label for object \(objectNumber)/\(totalLabels) sent with ObjectID: \(objectID).")
        }
    }

    // Helper function to get the current date and time
    func getCurrentDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateTime = dateFormatter.string(from: Date())
        print("Current date and time: \(currentDateTime)")
        return currentDateTime
    }

    // Close the connection with the printer
    func closePrinterConnection(connection: ZebraPrinterConnection) {
        connection.close()
        print("Printer connection closed.")
    }
}
