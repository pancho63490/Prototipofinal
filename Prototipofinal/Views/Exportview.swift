import SwiftUI

struct ExportView: View {
    @State private var truckData: [Truck] = [] // Truck data
    @State private var scannedObjectIDs: Set<String> = [] // Record of scanned ObjectIDs
    @State private var isLoading = false // Loading indicator
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var currentObjectID: String? // ObjectID being scanned
    @State private var isScanning = false // Active scanning control
    @State private var expandedTrucks: Set<UUID> = [] // Tracks expanded trucks
    @State private var searchText: String = "" // Search text for filtering trucks
    
    // Variables para la alerta final de exportación:
    @State private var showCompletionAlert = false
    @State private var completionMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading data...")
                    } else {
                        List(filteredTruckData, id: \.id) { truck in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedTrucks.contains(truck.id) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedTrucks.insert(truck.id)
                                        } else {
                                            expandedTrucks.remove(truck.id)
                                        }
                                    }
                                )
                            ) {
                                ForEach(truck.items) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Object ID: \(item.objectID)")
                                                .font(.subheadline)
                                            Text("Reference: \(item.TrackingNumber)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Location: \(item.location)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if scannedObjectIDs.contains(item.objectID) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Button(action: {
                                                currentObjectID = item.objectID
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
                                        Text("Export")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .padding(.top, 10)
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Truck: \(truck.deliveryType)")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: expandedTrucks.contains(truck.id) ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    // Barra de progreso
                                    ProgressView(value: progress(for: truck))
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search trucks")
                    }
                    Spacer()
                }
                .onAppear(perform: fetchTruckData)
                .navigationTitle("Export")
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
                // Alerta final para el estado de la exportación
                .alert(isPresented: $showCompletionAlert) {
                    Alert(
                        title: Text("Export Result"),
                        message: Text(completionMessage),
                        dismissButton: .default(Text("OK"))
                    )
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
                                Text("Cancel")
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

    // Computed property to filter trucks based on search text
    var filteredTruckData: [Truck] {
        if searchText.isEmpty {
            return truckData
        } else {
            return truckData.filter { $0.deliveryType.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Function to calculate progress for a truck
    func progress(for truck: Truck) -> Double {
        let scannedCount = truck.items.filter { scannedObjectIDs.contains($0.objectID) }.count
        return Double(scannedCount) / Double(truck.items.count)
    }

    // Function to fetch truck data from the API
    func fetchTruckData() {
        isLoading = true
        //let urlString = "https://run.mocky.io/v3/e54e46e5-6e26-437f-a830-f0814ee77f93"
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/TrukData"
        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL.")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    showError(message: "Error fetching data: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    showError(message: "Invalid data.")
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode([Truck].self, from: data)
                    truckData = decodedData
                    print("Data decoded successfully: \(truckData)")
                } catch let decodingError {
                    showError(message: "Error decoding data: \(decodingError.localizedDescription)")
                    print("Decoding error details: \(decodingError)")
                }
            }
        }
        task.resume()
    }

    // Validate if the scanned code matches the Object ID
    func validateScannedObjectID(_ scannedCode: String?) {
        guard let code = scannedCode?.trimmingCharacters(in: .whitespacesAndNewlines),
              let objectID = currentObjectID?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("Invalid code or ObjectID.")
            return
        }

        print("Scanned code: '\(code)'")
        print("Expected ObjectID: '\(objectID)'")

        if code == objectID {
            scannedObjectIDs.insert(objectID)
            print("Successfully scanned: \(objectID)")
        } else {
            showError(message: "The scanned code does not match the Object ID.")
            print("Error: Codes do not match.")
        }
    }

    // Check if all objects for the truck have been scanned
    func allObjectsScanned(for truck: Truck) -> Bool {
        truck.items.allSatisfy { scannedObjectIDs.contains($0.objectID) }
    }

    // Marca como completado, enviando *uno por uno* los TrackingNumber de cada Item
    func markTruckAsCompleted(_ truck: Truck) {
        // Usamos DispatchGroup para saber cuándo terminaron todas las solicitudes
        let dispatchGroup = DispatchGroup()
        var failedItems: [String] = []

        for item in truck.items {
            dispatchGroup.enter()
            sendTrackingRequest(for: item) { success in
                if !success {
                    failedItems.append(item.TrackingNumber)
                }
                dispatchGroup.leave()
            }
        }

        // Cuando todas las solicitudes terminan, se llama a notify
        dispatchGroup.notify(queue: .main) {
            if failedItems.isEmpty {
                completionMessage = "All items exported successfully."
                // Si todo fue exitoso, recargamos la data
                fetchTruckData()
            } else {
                completionMessage = "Some items could not be exported: \(failedItems.joined(separator: ", "))"
            }
            showCompletionAlert = true
        }
    }

    // Envía una solicitud PUT por cada TrackingNumber; incluye un callback de éxito/fallo
    // Envía una solicitud PUT por cada TrackingNumber; incluye un callback de éxito/fallo
    func sendTrackingRequest(for item: Item, completion: @escaping (Bool) -> Void) {
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/TrukData/UpdateBill"

        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "DeliveryType": item.TrackingNumber
        ]

        // Imprime en consola el debug de lo que se envía
        print("DEBUG: Enviando solicitud PUT a \(urlString) con el siguiente cuerpo:")
        print(body)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error.localizedDescription)")
            completion(false)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending data for TrackingNumber \(item.TrackingNumber): \(error.localizedDescription)")
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid server response for TrackingNumber \(item.TrackingNumber).")
                    completion(false)
                    return
                }

                if httpResponse.statusCode == 200 {
                    print("Successfully sent data for TrackingNumber: \(item.TrackingNumber)")
                    completion(true)
                } else {
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("Server error for TrackingNumber \(item.TrackingNumber): \(responseBody)")
                    } else {
                        print("Unknown server error for TrackingNumber \(item.TrackingNumber).")
                    }
                    completion(false)
                }
            }
        }
        task.resume()
    }

    // Show error in alert
    func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

// Data model for trucks
struct Truck: Codable, Identifiable {
    let id = UUID()
    let deliveryType: String
    let items: [Item]

    enum CodingKeys: String, CodingKey {
        case deliveryType = "TruckBox"
        case items = "Items"
    }
}

// Data model for items within a truck
struct Item: Codable, Identifiable {
    let id = UUID()
    let objectID: String
    let location: String
    let TrackingNumber: String

    enum CodingKeys: String, CodingKey {
        case objectID = "ObjectID"
        case location = "Location"
        case TrackingNumber = "TrackingNumber"
    }
}
