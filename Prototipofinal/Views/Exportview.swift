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

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading data...")
                    } else {
                        List(truckData, id: \.id) { truck in
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
                                        Text("Send and Reload")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .padding(.top, 10)
                                }
                            } label: {
                                HStack {
                                    Text("Truck: \(truck.deliveryType)")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: expandedTrucks.contains(truck.id) ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle()) // Improved list style for better appearance
                    }
                    Spacer()
                }
                .onAppear(perform: fetchTruckData)
                .navigationTitle("Export")
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
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

    // Function to fetch truck data from the API
    func fetchTruckData() {
        isLoading = true
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/TrukData"
        //let urlString = "https://run.mocky.io/v3/6b690ebe-892d-4b10-a70e-841c595b8d64"
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

        // Print both values to the console for comparison
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

    // Mark the truck as completed by sending a PUT request
    func markTruckAsCompleted(_ truck: Truck) {
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/TrukData/UpdateBill"

        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Request body with the correct format
        let body: [String: Any] = [
            "DeliveryType": truck.deliveryType
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            showError(message: "Error encoding data: \(error.localizedDescription)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError(message: "Error sending data: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    showError(message: "Invalid server response.")
                    return
                }

                if httpResponse.statusCode == 200 {
                    print("Data sent successfully. Truck: \(truck.deliveryType)")
                    fetchTruckData() // Reload data after success
                } else {
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("Server response error: \(responseBody)")
                        showError(message: "Server error: \(responseBody)")
                    } else {
                        showError(message: "Unknown server error.")
                    }
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
        case deliveryType = "DeliveryType"
        case items = "Items"
    }
}

// Data model for items within a truck
struct Item: Codable, Identifiable {
    let id = UUID()
    let objectID: String
    let location: String

    enum CodingKeys: String, CodingKey {
        case objectID = "ObjectID"
        case location = "Location"
    }
}

