import SwiftUI

struct PrintView: View {
    var referenceNumber: String
    var trackingData: [TrackingData]
    var customLabels: Int
    var useCustomLabels: Bool
    
    @Environment(\.dismiss) var dismiss // Recommended usage in modern SwiftUI
    @Binding var finalObjectIDs: [String] // To pass the generated Object IDs to the main view
    
    @State private var isPrintingComplete = false
    @State private var currentPallet = 1
    @State private var objectIDs: [String] = [] // Array to store Object IDs as strings
    
    // Enum to handle different types of alerts
    enum ActiveAlert: Identifiable {
        case genericError(message: String, retryAction: () -> Void, reprintAction: () -> Void)
        case objectIDsExist(message: String)
        
        var id: String {
            switch self {
            case .genericError(let message, _, _):
                return "genericError-\(message)"
            case .objectIDsExist(let message):
                return "objectIDsExist-\(message)"
            }
        }
    }
    
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        VStack {
            Text("Printing in Progress")
                .font(.title)
                .padding()
            
            if !isPrintingComplete {
                ProgressView("Printing \(currentPallet)/\(totalLabels()) labels...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Text("Printing Complete")
                    .foregroundColor(.green)
                    .font(.headline)
                    .padding()
            }
        }
        .onAppear {
            print("PrintView appeared. Starting Object ID request and print process.")
            requestObjectIDsAndStartPrintProcess()
        }
        .onChange(of: isPrintingComplete) { complete in
            if complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.finalObjectIDs = objectIDs // Pass the generated Object IDs
                    self.dismiss() // Return to the main menu
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .genericError(let message, let retryAction, let reprintAction):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    primaryButton: .default(Text("Cancel")) {
                        // Dismiss the view when "Cancel" is tapped
                        self.dismiss()
                    },
                    secondaryButton: .default(Text("Reprint")) {
                        reprintAction()
                    }
                )
            case .objectIDsExist(let message):
                return Alert(
                    title: Text("Existing Object IDs"),
                    message: Text(message),
                    primaryButton: .default(Text("Reprint")) {
                        fetchExistingObjectIDs()
                    },
                    secondaryButton: .cancel(Text("Cancel")) {
                        print("Alert dismissed. Closing view due to an error.")
                        self.dismiss() // Return to the start
                    }
                )
            }
        }
    }
    
    // Function to count the number of distinct materials in trackingData
    func distinctMaterialCount() -> Int {
        let uniqueMaterials = Set(trackingData.map { $0.material })
        print("Number of distinct materials: \(uniqueMaterials.count)")
        return uniqueMaterials.count
    }
    
    // Function to get the total number of labels to print
    func totalLabels() -> Int {
        return useCustomLabels ? customLabels : distinctMaterialCount()
    }
    
    // Function to request Object IDs from the API and then start the printing process
    func requestObjectIDsAndStartPrintProcess() {
        let totalLabels = self.totalLabels()
        guard let firstTrackingData = trackingData.first else {
            showErrorAlert(.genericError(message: "No tracking data available.", retryAction: {
                self.requestObjectIDsAndStartPrintProcess()
            }, reprintAction: {
                self.fetchExistingObjectIDs()
            }))
            return
        }
        
        let requestData: [String: Any] = [
            "QTY": totalLabels,
            "REF_NUM": firstTrackingData.externalDeliveryID
        ]
        
        print("Total labels to print: \(totalLabels)")
        print("Sending request to API with the following data: \(requestData)")
        
        APIServiceobj().requestObjectIDs(requestData: requestData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let objectIDResponse):
                    print("API response data: \(objectIDResponse)")
                    guard let objectIDs = objectIDResponse.objectIDs, !objectIDs.isEmpty else {
                        showErrorAlert(.genericError(message: "No Object IDs received from the API.", retryAction: {
                            self.requestObjectIDsAndStartPrintProcess()
                        }, reprintAction: {
                            self.fetchExistingObjectIDs()
                        }))
                        return
                    }
                    self.objectIDs = objectIDs.map { String($0) }
                    self.startPrintProcess()
                case .failure(let error):
                    if case APIServiceobj.APIError.objectIDsAlreadyExist(let message) = error {
                        // Show an alert to reprint using existing Object IDs
                        print("Object IDs already exist for REF_NUM: \(self.referenceNumber).")
                        self.activeAlert = .objectIDsExist(message: "Object IDs already exist for this REF_NUM. Would you like to reprint using the existing Object IDs?")
                    } else {
                        showErrorAlert(.genericError(message: "Error obtaining Object IDs: \(error.localizedDescription)", retryAction: {
                            self.requestObjectIDsAndStartPrintProcess()
                        }, reprintAction: {
                            self.fetchExistingObjectIDs()
                        }))
                    }
                }
            }
        }
    }
    
    // Function to start the printing process after obtaining Object IDs
    func startPrintProcess() {
        currentPallet = 1
        let printController = PrintViewController()
        printNextPallet(printController: printController)
    }
    
    // Function to print each label using the Object IDs
    func printNextPallet(printController: PrintViewController) {
        let totalLabels = self.totalLabels()
        
        guard currentPallet <= totalLabels else {
            isPrintingComplete = true
            return
        }
        
        let objectID: String
        
        if currentPallet <= objectIDs.count {
            objectID = objectIDs[currentPallet - 1]
        } else {
            showErrorAlert(.genericError(message: "Not enough Object IDs generated to complete printing.", retryAction: {
                self.startPrintProcess()
            }, reprintAction: {
                self.fetchExistingObjectIDs()
            }))
            return
        }
        
        print("Starting print for pallet \(currentPallet) with ObjectID: \(objectID)")
        
        printController.startPrinting(
            trackingNumber: referenceNumber,
            invoiceNumber: referenceNumber,
            palletNumber: currentPallet,
            objectID: objectID,
            totalLabels: totalLabels
        ) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("Label \(self.currentPallet)/\(self.totalLabels()) printed with ObjectID: \(objectID)")
                    self.currentPallet += 1
                    self.printNextPallet(printController: printController)
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.showErrorAlert(.genericError(message: error.localizedDescription, retryAction: {
                        self.printNextPallet(printController: printController)
                    }, reprintAction: {
                        self.fetchExistingObjectIDs()
                    }))
                }
            }
        }
    }
    
    // Function to show the error message in the alert
    func showErrorAlert(_ alertType: ActiveAlert) {
        print("Error: \(alertType)")
        self.activeAlert = alertType
    }
    
    // Function to handle reprinting (call the second API)
    func fetchExistingObjectIDs() {
        guard let firstTrackingData = trackingData.first else {
            showErrorAlert(.genericError(message: "No tracking data available for reprinting.", retryAction: {
                self.fetchExistingObjectIDs()
            }, reprintAction: {
                // Optional: You could add another action or simply close
                self.dismiss()
            }))
            return
        }
        
        let externalDeliveryID = firstTrackingData.externalDeliveryID
        print("Fetching existing Object IDs for REF_NUM: \(externalDeliveryID)")
        
        APIServiceobj().searchObjectIDs(x: externalDeliveryID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let backupResponse):
                    print("Search response data: \(backupResponse)")
                    guard let backupObjectIDs = backupResponse.objectIDs, !backupObjectIDs.isEmpty else {
                        showErrorAlert(.genericError(message: "No existing Object IDs found for this REF_NUM.", retryAction: {
                            self.fetchExistingObjectIDs()
                        }, reprintAction: {
                            self.dismiss()
                        }))
                        return
                    }
                    self.objectIDs = backupObjectIDs.map { String($0) }
                    self.startPrintProcess()
                case .failure(let error):
                    showErrorAlert(.genericError(message: "Error searching for existing Object IDs: \(error.localizedDescription)", retryAction: {
                        self.fetchExistingObjectIDs()
                    }, reprintAction: {
                        self.dismiss()
                    }))
                }
            }
        }
    }
}
/*import SwiftUI
 
 struct PrintView: View {
     var referenceNumber: String
     var trackingData: [TrackingData]
     var customLabels: Int
     var useCustomLabels: Bool
     
     @Environment(\.dismiss) var dismiss // Recommended usage in modern SwiftUI
     @Binding var finalObjectIDs: [String] // To pass the generated Object IDs to the main view
     
     @State private var isPrintingComplete = false
     @State private var objectIDs: [String] = [] // Array to store Object IDs as strings
     
     // Enum to handle different types of alerts
     enum ActiveAlert: Identifiable {
         case genericError(message: String, retryAction: () -> Void, reprintAction: () -> Void)
         case objectIDsExist(message: String)
         
         var id: String {
             switch self {
             case .genericError(let message, _, _):
                 return "genericError-\(message)"
             case .objectIDsExist(let message):
                 return "objectIDsExist-\(message)"
             }
         }
     }
     
     @State private var activeAlert: ActiveAlert?
     
     var body: some View {
         VStack {
             Text("Printing in Progress")
                 .font(.title)
                 .padding()
             
             if !isPrintingComplete {
                 ProgressView("Simulating printing of labels...")
                     .progressViewStyle(CircularProgressViewStyle())
                     .padding()
             } else {
                 Text("Printing Complete")
                     .foregroundColor(.green)
                     .font(.headline)
                     .padding()
             }
         }
         .onAppear {
             print("PrintView appeared. Starting Object ID request and print process.")
             requestObjectIDsAndStartPrintProcess()
         }
         .onChange(of: isPrintingComplete) { complete in
             if complete {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                     self.finalObjectIDs = objectIDs // Pass the generated Object IDs
                     self.dismiss() // Return to the main menu
                 }
             }
         }
         .alert(item: $activeAlert) { alert in
             switch alert {
             case .genericError(let message, let retryAction, let reprintAction):
                 return Alert(
                     title: Text("Error"),
                     message: Text(message),
                     primaryButton: .default(Text("Retry")) {
                         retryAction()
                     },
                     secondaryButton: .default(Text("Reprint")) {
                         reprintAction()
                     }
                 )
             case .objectIDsExist(let message):
                 return Alert(
                     title: Text("Existing Object IDs"),
                     message: Text(message),
                     primaryButton: .default(Text("Reprint")) {
                         fetchExistingObjectIDs()
                     },
                     secondaryButton: .cancel(Text("Cancel")) {
                         print("Alert dismissed. Closing view due to an error.")
                         self.dismiss() // Return to the start
                     }
                 )
             }
         }
     }
     
     // Function to count the number of distinct materials in trackingData
     func distinctMaterialCount() -> Int {
         let uniqueMaterials = Set(trackingData.map { $0.material })
         print("Number of distinct materials: \(uniqueMaterials.count)")
         return uniqueMaterials.count
     }
     
     // Function to get the total number of labels to print
     func totalLabels() -> Int {
         return useCustomLabels ? customLabels : distinctMaterialCount()
     }
     
     // Function to request Object IDs from the API and then start the printing process
     func requestObjectIDsAndStartPrintProcess() {
         let totalLabels = self.totalLabels()
         guard let firstTrackingData = trackingData.first else {
             showErrorAlert(.genericError(message: "No tracking data available.", retryAction: {
                 self.requestObjectIDsAndStartPrintProcess()
             }, reprintAction: {
                 self.fetchExistingObjectIDs()
             }))
             return
         }
         
         let requestData: [String: Any] = [
             "QTY": totalLabels,
             "REF_NUM": firstTrackingData.externalDeliveryID
         ]
         
         print("Total labels to print: \(totalLabels)")
         print("Sending request to API with the following data: \(requestData)")
         
         APIServiceobj().requestObjectIDs(requestData: requestData) { result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let objectIDResponse):
                     print("API response data: \(objectIDResponse)")
                     guard let objectIDs = objectIDResponse.objectIDs, !objectIDs.isEmpty else {
                         showErrorAlert(.genericError(message: "No Object IDs received from the API.", retryAction: {
                             self.requestObjectIDsAndStartPrintProcess()
                         }, reprintAction: {
                             self.fetchExistingObjectIDs()
                         }))
                         return
                     }
                     self.objectIDs = objectIDs.map { String($0) }
                     self.startPrintProcess()
                 case .failure(let error):
                     if case APIServiceobj.APIError.objectIDsAlreadyExist(let message) = error {
                         // Show an alert to reprint using existing Object IDs
                         print("Object IDs already exist for REF_NUM: \(self.referenceNumber).")
                         self.activeAlert = .objectIDsExist(message: "Object IDs already exist for this REF_NUM. Would you like to reprint using the existing Object IDs?")
                     } else {
                         showErrorAlert(.genericError(message: "Error obtaining Object IDs: \(error.localizedDescription)", retryAction: {
                             self.requestObjectIDsAndStartPrintProcess()
                         }, reprintAction: {
                             self.fetchExistingObjectIDs()
                         }))
                     }
                 }
             }
         }
     }
     
     // Función modificada para iniciar el proceso de impresión (Simulación)
     func startPrintProcess() {
         // Simula el proceso de impresión completando todas las etiquetas después de un breve retraso
         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
             self.isPrintingComplete = true
             self.finalObjectIDs = self.objectIDs // Asegurar que finalObjectIDs se asignen correctamente
         }
     }
     
     // Function to show the error message in the alert
     func showErrorAlert(_ alertType: ActiveAlert) {
         print("Error: \(alertType)")
         self.activeAlert = alertType
     }
     
     // Function to handle reprinting (call the second API)
     func fetchExistingObjectIDs() {
         guard let firstTrackingData = trackingData.first else {
             showErrorAlert(.genericError(message: "No tracking data available for reprinting.", retryAction: {
                 self.fetchExistingObjectIDs()
             }, reprintAction: {
                 // Optional: You could add another action or simply close
                 self.dismiss()
             }))
             return
         }
         
         let externalDeliveryID = firstTrackingData.externalDeliveryID
         print("Fetching existing Object IDs for REF_NUM: \(externalDeliveryID)")
         
         APIServiceobj().searchObjectIDs(x: externalDeliveryID) { result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let backupResponse):
                     print("Search response data: \(backupResponse)")
                     guard let backupObjectIDs = backupResponse.objectIDs, !backupObjectIDs.isEmpty else {
                         showErrorAlert(.genericError(message: "No existing Object IDs found for this REF_NUM.", retryAction: {
                             self.fetchExistingObjectIDs()
                         }, reprintAction: {
                             self.dismiss()
                         }))
                         return
                     }
                     self.objectIDs = backupObjectIDs.map { String($0) }
                     self.startPrintProcess()
                 case .failure(let error):
                     showErrorAlert(.genericError(message: "Error searching for existing Object IDs: \(error.localizedDescription)", retryAction: {
                         self.fetchExistingObjectIDs()
                     }, reprintAction: {
                         self.dismiss()
                     }))
                 }
             }
         }
     }
 }
*/
