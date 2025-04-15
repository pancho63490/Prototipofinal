import SwiftUI

// MARK: - Models for Decoding JSON Response

struct DeliveryResponse2: Codable {
    let data: [Delivery]
}

struct Delivery: Codable, Identifiable {
    var id: String { externalDeliveryID }
    
    let externalDeliveryID: String
    let material: String
    let deliveryQty: String
    let supplierName: String
    let src: String

    enum CodingKeys: String, CodingKey {
        case externalDeliveryID = "EXTERNAL_DELVRY_ID"
        case material = "MATERIAL"
        case deliveryQty = "DELIVERY_QTY"
        case supplierName = "SUPPLIER_NAME"
        case src = "SRC"
    }
}

// MARK: - Main View

struct DeliverySearchView: View {
    @State private var searchText = ""
    @State private var deliveries: [Delivery] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Optional banner view at the top, if you have one defined
            Banner()
            
            NavigationView {
                VStack {
                    // Search bar
                    HStack {
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            fetchDeliveries()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                        }
                        .accessibilityLabel("Search")
                    }
                    .padding()
                    
                    // Loading indicator or error message display
                    if isLoading {
                        ProgressView("Loading...")
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // List of search results
                    List(deliveries) { delivery in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("External Delivery: \(delivery.externalDeliveryID)")
                                .font(.headline)
                            Text("Material: \(delivery.material)")
                            Text("Quantity: \(delivery.deliveryQty)")
                            Text("Supplier: \(delivery.supplierName)")
                            Text("SRC: \(delivery.src)")
                        }
                        .padding(8)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationTitle("Delivery Search")
            }
        }
    }
    
    // MARK: - Function to Make the PUT Request
    func fetchDeliveries() {
        // Trim search text and check if not empty.
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            deliveries = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/updatefiles") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON body with search text
        let body: [String: String] = ["Search": searchText]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Connection error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Server returned an error."
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(DeliveryResponse2.self, from: data)
                    deliveries = responseData.data
                } catch {
                    errorMessage = "Decoding error: \(error.localizedDescription)"
                    print("Received data: \(String(data: data, encoding: .utf8) ?? "Invalid Format")")
                }
            }
        }.resume()
    }
}

