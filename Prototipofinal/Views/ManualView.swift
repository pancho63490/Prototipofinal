import SwiftUI

struct ManualInsertionView: View {
    // State variables for External Delivery ID and Supplier Name
    @State private var externalDeliveryID = ""
    @State private var supplierName = ""
    
    // List of materials
    @State private var materials: [Material] = []
    @State private var showingAddMaterialSheet = false
    
    // Alert and error messages
    @State private var alertItem: AlertItem?
    
    // Loading indicator
    @State private var isLoading = false
    
    // Environment for presentation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Application Title
            VStack {
                Image(systemName: "shippingbox.fill") // Replace with your logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("XDOCK")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // External Delivery ID and Supplier Name Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery Information")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "doc.text", title: "External Delivery ID", text: $externalDeliveryID)
                        
                        CustomTextFieldWithIcon(icon: "person.crop.circle", title: "Supplier Name", text: $supplierName)
                    }
                    
                    // Materials Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Materials List")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // List of added materials
                        ForEach(materials) { material in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Code: \(material.code)")
                                            .fontWeight(.bold)
                                        Text("Quantity: \(material.quantity) \(material.unit)")
                                    }
                                    Spacer()
                                    Button(action: {
                                        deleteMaterial(material)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                HStack {
                                    Text("Gross Weight: \(material.grossWeight) kg")
                                    Spacer()
                                    Text("Net Weight: \(material.netWeight) kg")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Button to add material
                        Button(action: {
                            showingAddMaterialSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Material")
                            }
                        }
                        .sheet(isPresented: $showingAddMaterialSheet) {
                            // Sheet to add material
                            AddMaterialSheet(materials: $materials)
                        }
                    }
                    
                    // Send Button
                    Button(action: {
                        hideKeyboard()
                        submitData()
                    }) {
                        Text("Send")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // Loading Indicator
                    if isLoading {
                        ProgressView("Sending data...")
                            .padding()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Manual Data Entry")
        .alert(item: $alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK")) {
                    if alertItem.title == "Success" {
                        // Navigate back after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            )
        }
        .onTapGesture {
            hideKeyboard() // Hide keyboard when tapping outside
        }
    }
    
    // Function to delete a material
    private func deleteMaterial(_ material: Material) {
        if let index = materials.firstIndex(where: { $0.id == material.id }) {
            materials.remove(at: index)
        }
    }
    
    // Function to send data to the API
    private func submitData() {
        // Validate required fields
        if externalDeliveryID.isEmpty ||
            supplierName.isEmpty ||
            materials.isEmpty {
            alertItem = AlertItem(title: "Error", message: "Please complete all required fields.")
            return
        }
        
        isLoading = true
        
        // Create TrackingData objects
        let trackingDataList = materials.map { material in
            TrackingData2(
                externalDeliveryID: externalDeliveryID,
                material: material.code,
                deliveryQty: material.quantity,
                deliveryNo: externalDeliveryID, // Assign unit
                supplierVendor: "0",
                supplierName: supplierName,
                container: "x",
                src: "Manual",
                unit: material.unit, // Assign "Manual" as per your requirement
                grossWeight: material.grossWeight,
                netWeight: material.netWeight
            )
        }
        
        // Send each TrackingData to the API
        let group = DispatchGroup()
        var encounteredError: Error?
        
        for trackingData in trackingDataList {
            group.enter()
            DeliveryAPIService.shared.sendTrackingData(trackingData) { result in
                switch result {
                case .success():
                    print("TrackingData sent successfully: \(trackingData)")
                case .failure(let error):
                    print("Error sending TrackingData: \(error.localizedDescription)")
                    encounteredError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            if let error = encounteredError {
                alertItem = AlertItem(title: "Error", message: "Error sending data: \(error.localizedDescription)")
            } else {
                alertItem = AlertItem(title: "Success", message: "Data sent successfully.")
                clearFields()
            }
        }
    }
    
    // Function to clear fields after sending
    private func clearFields() {
        externalDeliveryID = ""
        supplierName = ""
        materials.removeAll()
    }
    
    // Function to hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Custom Text Field with Icon
    struct CustomTextFieldWithIcon: View {
        var icon: String
        var title: String
        @Binding var text: String
        var keyboardType: UIKeyboardType = .default
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.leading, 10)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // Structure for Material
    struct Material: Identifiable {
        let id = UUID()
        var code: String
        var quantity: String
        var unit: String // Unit of measurement
        var grossWeight: String // Gross weight in kg
        var netWeight: String // Net weight in kg
    }
    
    // View to Add Material
    struct AddMaterialSheet: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var materials: [Material]
        
        @State private var materialCode = ""
        @State private var quantity = ""
        @State private var selectedUnit = "pcs" // Default unit of measurement
        @State private var grossWeight = ""
        @State private var netWeight = ""
        
        // Unit options
        let units = ["Liters", "kg", "Pallets", "pcs", "Grams", "Meters", "cm"]
        
        // For camera scanner
        @State private var isShowingScanner = false
        @State private var isShowingQuantityScanner = false
        @State private var isShowingGrossWeightScanner = false
        @State private var isShowingNetWeightScanner = false
        
        // NumberFormatter to validate quantity and weights
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Material Code
                        HStack {
                            CustomTextFieldWithIcon(icon: "barcode.viewfinder", title: "Material Code", text: $materialCode)
                            
                            Button(action: {
                                // Open scanner for code
                                isShowingScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingScanner) {
                                // Implement your scanner view here
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                                    materialCode = code
                                    isShowingScanner = false
                                })
                            }
                        }
                        
                        // Quantity
                        HStack {
                            CustomTextFieldWithIcon(icon: "number", title: "Quantity", text: $quantity, keyboardType: .decimalPad)
                            
                            Button(action: {
                                // Open scanner for quantity
                                isShowingQuantityScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingQuantityScanner) {
                                // Implement your scanner view here
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { scannedQuantity in
                                    // Validate that the scanned quantity is numeric
                                    if let _ = numberFormatter.number(from: scannedQuantity) {
                                        quantity = scannedQuantity
                                    } else {
                                        // Handle error if quantity is not valid
                                        // You can implement an alert here if desired
                                    }
                                    isShowingQuantityScanner = false
                                })
                            }
                        }
                        
                        // Gross Weight
                        HStack {
                            CustomTextFieldWithIcon(icon: "scalemass", title: "Gross Weight (kg)", text: $grossWeight, keyboardType: .decimalPad)
                            
                            Button(action: {
                                // Open scanner for gross weight
                                isShowingGrossWeightScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingGrossWeightScanner) {
                                // Implement your scanner view here
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { scannedGrossWeight in
                                    // Validate that the scanned gross weight is numeric
                                    if let _ = numberFormatter.number(from: scannedGrossWeight) {
                                        grossWeight = scannedGrossWeight
                                    } else {
                                        // Handle error if gross weight is not valid
                                        // You can implement an alert here if desired
                                    }
                                    isShowingGrossWeightScanner = false
                                })
                            }
                        }
                        
                        // Net Weight
                        HStack {
                            CustomTextFieldWithIcon(icon: "scalemass.fill", title: "Net Weight (kg)", text: $netWeight, keyboardType: .decimalPad)
                            
                            Button(action: {
                                // Open scanner for net weight
                                isShowingNetWeightScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingNetWeightScanner) {
                                // Implement your scanner view here
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { scannedNetWeight in
                                    // Validate that the scanned net weight is numeric
                                    if let _ = numberFormatter.number(from: scannedNetWeight) {
                                        netWeight = scannedNetWeight
                                    } else {
                                        // Handle error if net weight is not valid
                                        // You can implement an alert here if desired
                                    }
                                    isShowingNetWeightScanner = false
                                })
                            }
                        }
                        
                        // Unit of Measurement Picker
                        Picker("Unit of Measurement", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Button to add material
                        Button(action: {
                            // Add material to the list if quantity and weights are numeric
                            if let _ = numberFormatter.number(from: quantity),
                               let _ = numberFormatter.number(from: grossWeight),
                               let _ = numberFormatter.number(from: netWeight),
                               !materialCode.isEmpty {
                                let newMaterial = Material(
                                    code: materialCode,
                                    quantity: quantity,
                                    unit: selectedUnit,
                                    grossWeight: grossWeight,
                                    netWeight: netWeight
                                )
                                materials.append(newMaterial)
                                // Clear fields
                                materialCode = ""
                                quantity = ""
                                grossWeight = ""
                                netWeight = ""
                                selectedUnit = units.first ?? "pcs" // Reset to default unit
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                // Show error if any field is not valid
                                // You can implement an alert here if desired
                            }
                        }) {
                            Text("Add")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((materialCode.isEmpty ||
                                            quantity.isEmpty ||
                                            grossWeight.isEmpty ||
                                            netWeight.isEmpty ||
                                            numberFormatter.number(from: quantity) == nil ||
                                            numberFormatter.number(from: grossWeight) == nil ||
                                            numberFormatter.number(from: netWeight) == nil) ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(materialCode.isEmpty ||
                                  quantity.isEmpty ||
                                  grossWeight.isEmpty ||
                                  netWeight.isEmpty ||
                                  numberFormatter.number(from: quantity) == nil ||
                                  numberFormatter.number(from: grossWeight) == nil ||
                                  numberFormatter.number(from: netWeight) == nil)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Add Material")
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
}

// Structure for Alerts
struct AlertItem: Identifiable {
    var id = UUID()
    var title: String
    var message: String
}

// Consolidated TrackingData Model
struct TrackingData2: Codable {
    let externalDeliveryID: String
    let material: String
    let deliveryQty: String
    let deliveryNo: String
    let supplierVendor: String
    let supplierName: String
    let container: String?
    let src: String?
    let unit: String?
    let grossWeight: String? // New field
    let netWeight: String?   // New field
    
    enum CodingKeys: String, CodingKey {
        case externalDeliveryID = "EXTERNAL_DELVRY_ID"
        case material = "MATERIAL"
        case deliveryQty = "DELIVERY_QTY"
        case deliveryNo = "DELIVERY_NO"
        case supplierVendor = "SUPPLIER_VENDOR"
        case supplierName = "SUPPLIER_NAME"
        case container = "CONTAINER"
        case src = "SRC"
        case unit = "UNIT"
        case grossWeight = "PESO_BRUTO" // New CodingKey
        case netWeight = "PESO_NETO"     // New CodingKey
    }
}

struct ManualInsertionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualInsertionView()
    }
}
