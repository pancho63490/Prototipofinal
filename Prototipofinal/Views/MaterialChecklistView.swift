import SwiftUI

struct MaterialChecklistView: View {
    @EnvironmentObject var shipmentState: ShipmentState
    
    var trackingData: [TrackingData]
    var objectIDs: [String]

    @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
    @State private var locationsPerObjectID: [String: String] = [:]
    @State private var remainingQuantities: [String: Int] = [:]
    @State private var totalQuantities: [String: Int] = [:]

    @State private var selectedObjectID: String?
    @State private var scannedObjectIDs: Set<String> = []
    
    @State private var newMaterial = ""
    @State private var newQuantityText = ""
    @State private var newLocation = ""
    @State private var newGeneralLocation = ""

    @State private var showingAddMaterialSheet = false
    @State private var showingAssignLocationSheet = false
    @State private var showingAssignGeneralLocationSheet = false
    @State private var showingObjectIDScanner = false
    @State private var showingMaterialScanner = false
    @State private var showingQuantityScanner = false

    enum ActiveAlert: Identifiable {
        case error
        case success
        case missingQuantities
        case confirm

        var id: Int {
            self.hashValue
        }
    }
    @State private var activeAlert: ActiveAlert?
    @State private var errorMessage: String = ""
    @State private var missingMaterials: [(material: String, quantity: Int)] = []

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // SECTION: Shipment Type Information
                Section(header: Text("Shipment Information")) {
                    Text("Shipment Type: \(shipmentState.selectedInboundType ?? "N/A")")
                        .font(.headline)
                }
                
                // SECTION: Picker to select Object ID
                Section(header: Text("Select an Object ID")) {
                    Picker("Object ID", selection: $selectedObjectID) {
                        Text("Choose...").tag(String?.none)
                        ForEach(objectIDs, id: \.self) { objectID in
                            Text(objectID).tag(Optional(objectID))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // SECTION: Details of the selected Object ID
                if let objectID = selectedObjectID {
                    Section(header: Text("Details of \(objectID)")) {
                        
                        // Scan Object ID if it has not been scanned
                        if !scannedObjectIDs.contains(objectID) {
                            Button {
                                showingObjectIDScanner = true
                            } label: {
                                Label("Scan Object ID", systemImage: "qrcode.viewfinder")
                                    .foregroundColor(.orange)
                            }
                            
                        } else {
                            // Show assigned location or button to assign it
                            if let location = locationsPerObjectID[objectID] {
                                HStack {
                                    Text("Assigned Location:")
                                    Spacer()
                                    Text(location)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            Button {
                                showingAssignLocationSheet = true
                            } label: {
                                Label(
                                    locationsPerObjectID[objectID] != nil
                                    ? "Change Location"
                                    : "Assign Location",
                                    systemImage: "map"
                                )
                                .foregroundColor(.green)
                            }

                            // List of materials added to this Object ID
                            if let materials = materialsPerObjectID[objectID] {
                                // To prevent breaking the Form structure, use a ScrollView or a sub-Form instead of List
                                ScrollView {
                                    VStack(spacing: 10) {
                                        ForEach(materials) { entry in
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Material: \(entry.material)")
                                                        .font(.subheadline)
                                                    Text("Quantity: \(entry.quantity)")
                                                        .font(.footnote)
                                                }
                                                Spacer()
                                                // Button to delete a specific material (if you want to allow it individually)
                                                Button(role: .destructive) {
                                                    // Remove this entry
                                                    deleteMaterial(entry, for: objectID)
                                                } label: {
                                                    Image(systemName: "trash")
                                                }
                                            }
                                            Divider()
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                                .frame(minHeight: 100, maxHeight: 200)
                            }
                            
                            // Botón para agregar nuevo material
                            Button {
                                showingAddMaterialSheet = true
                            } label: {
                                Label("Add Material", systemImage: "plus")
                                    .foregroundColor(.blue)
                            }
                            .disabled(!scannedObjectIDs.contains(objectID) || trackingDataMaterials().isEmpty) // Deshabilitar si no hay materiales disponibles
                        }
                    }
                }
                
                // SECTION: Assign location to ALL
                Section {
                    Button {
                        showingAssignGeneralLocationSheet = true
                    } label: {
                        Label("Assign Location to All", systemImage: "location.fill")
                            .foregroundColor(.purple)
                    }
                }

                // SECTION: Remaining Quantities
                Section(header: Text("Remaining Quantities")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(remainingQuantities.keys.filter { remainingQuantities[$0]! > 0 }.sorted(), id: \.self) { material in
                                VStack {
                                    Text(material)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("Missing: \(remainingQuantities[material]!)")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Packing List Checklist")
            .toolbar {
                // Submit Button at the top right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeAlert = .confirm  // Establece el tipo de alerta a mostrar
                    } label: {
                        Text("Send")
                            .padding()  // Añade espacio alrededor del texto
                            .background(Color.blue)  // Fondo azul
                            .foregroundColor(.white)  // Texto blanco
                            .cornerRadius(8)  // Bordes redondeados
                    }
                }
            }
        }
        // onAppear to initialize quantities
        .onAppear {
            initializeRemainingQuantities()
        }
        // MARK: - Sheets and Alerts

        // Sheet: Assign location to a specific Object ID
        .sheet(isPresented: $showingAssignLocationSheet) {
            let optionalNewLocation = Binding<String?>(
                get: { self.newLocation },
                set: { self.newLocation = $0 ?? "" }
            )
            CameraScannerWrapperView(scannedCode: optionalNewLocation) { code in
                newLocation = code
                assignLocation()
                showingAssignLocationSheet = false
            }
        }
        // Sheet: Add material
        .sheet(isPresented: $showingAddMaterialSheet) {
            addMaterialSheetView
        }
        // Sheet: Assign location to ALL Object IDs
        .sheet(isPresented: $showingAssignGeneralLocationSheet) {
            let optionalNewGeneralLocation = Binding<String?>(
                get: { self.newGeneralLocation },
                set: { self.newGeneralLocation = $0 ?? "" }
            )
            CameraScannerWrapperView(scannedCode: optionalNewGeneralLocation) { code in
                newGeneralLocation = code
                assignGeneralLocation()
                showingAssignGeneralLocationSheet = false
            }
        }
        // Sheet: Scan Object ID
        .sheet(isPresented: $showingObjectIDScanner) {
            let scannedCodeBinding = Binding<String?>(
                get: { "" },
                set: { _ in }
            )
            CameraScannerWrapperView(scannedCode: scannedCodeBinding) { code in
                if let current = selectedObjectID {
                    if code == current {
                        scannedObjectIDs.insert(current)
                    } else {
                        showError(message: "The scanned code does not match \(current).")
                    }
                } else {
                    showError(message: "No Object ID has been selected.")
                }
                showingObjectIDScanner = false
            }
        }
        // Alerts
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .error:
                return Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            case .success:
                return Alert(
                    title: Text("Success"),
                    message: Text("Data sent successfully."),
                    dismissButton: .default(Text("OK"), action: {
                        resetData()
                        dismiss()
                    })
                )
            case .missingQuantities:
                return Alert(
                    title: Text("Missing Quantities"),
                    message: Text(missingMaterialsMessage()),
                    primaryButton: .destructive(Text("Continue")) {
                        sendData()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            case .confirm:
                return Alert(
                    title: Text("Are you sure?"),
                    message: Text("Are you sure you want to send this data?"),
                    primaryButton: .destructive(Text("Send")) {
                        checkForMissingQuantitiesAndSendData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Subview to add material
    private var addMaterialSheetView: some View {
        VStack {
            Text("Add Material")
                .font(.headline)
                .padding()

            // Text field + scanner button for Material
            HStack {
                TextField("Material", text: $newMaterial)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingMaterialScanner = true
                }) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding()

            // Lista de sugerencias de materiales (trackingData) filtrados
            List {
                ForEach(trackingDataMaterials(), id: \.self) { material in
                    Button {
                        newMaterial = material
                    } label: {
                        Text(material)
                    }
                }
            }
            .frame(maxHeight: 150)

            // Text field + scanner button for Quantity
            HStack {
                TextField("Quantity", text: $newQuantityText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    showingQuantityScanner = true
                }) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding()

            HStack {
                Button("Cancel") {
                    showingAddMaterialSheet = false
                    newMaterial = ""
                    newQuantityText = ""
                }
                .padding()

                Spacer()

                Button("Add") {
                    addMaterial()
                    showingAddMaterialSheet = false
                }
                .padding()
                .disabled(newMaterial.isEmpty || newQuantityText.isEmpty) // Deshabilitar si los campos están vacíos
            }
        }
        .padding()
        // Sheets to scan Material or Quantity
        .sheet(isPresented: $showingMaterialScanner) {
            let optionalNewMaterial = Binding<String?>(
                get: { self.newMaterial },
                set: { self.newMaterial = $0 ?? "" }
            )
            CameraScannerWrapperView(scannedCode: optionalNewMaterial) { code in
                newMaterial = code
                showingMaterialScanner = false
            }
        }
        .sheet(isPresented: $showingQuantityScanner) {
            let optionalNewQuantityText = Binding<String?>(
                get: { self.newQuantityText },
                set: { self.newQuantityText = $0 ?? "" }
            )
            CameraScannerWrapperView(scannedCode: optionalNewQuantityText) { code in
                newQuantityText = code
                showingQuantityScanner = false
            }
        }
    }

    // MARK: - Logic Functions

    /// Initializes remaining and total quantities based on trackingData
    private func initializeRemainingQuantities() {
        let grouped = Dictionary(grouping: trackingData, by: { $0.material })
        for (material, entries) in grouped {
            let totalQuantity = entries.reduce(0) { (result, data) -> Int in
                let qty = Int(data.deliveryQty) ?? 0
                return result + qty
            }
            remainingQuantities[material] = totalQuantity
            totalQuantities[material] = totalQuantity
        }
    }

    private func trackingDataMaterials() -> [String] {
        let materials = trackingData.map { $0.material }
        return Array(Set(materials))
            .filter { remainingQuantities[$0, default: 0] > 0 } // Filtrar materiales completados
            .sorted()
    }
 
    private func addMaterial() {
        guard let objectID = selectedObjectID else { return }
        let material = newMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityStr = newQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)

        if material.isEmpty || quantityStr.isEmpty {
            showError(message: "All fields are required.")
            return
        }

        if let quantity = Int(quantityStr), quantity > 0 {
            if let remaining = remainingQuantities[material], remaining >= quantity {
                remainingQuantities[material] = remaining - quantity
                let location = locationsPerObjectID[objectID] ?? ""
                let entry = MaterialEntry(id: UUID(), material: material, quantity: quantity, location: location)
                materialsPerObjectID[objectID, default: []].append(entry)
            } else {
                showError(message: "Insufficient quantity for material \(material).")
            }
        } else {
            showError(message: "Invalid quantity. Please enter a valid number.")
        }

        newMaterial = ""
        newQuantityText = ""
    }

    /// Deletes a single material entry
    private func deleteMaterial(_ entry: MaterialEntry, for objectID: String) {
        if var materials = materialsPerObjectID[objectID],
           let index = materials.firstIndex(where: { $0.id == entry.id }) {
            // Return the deleted quantity to inventory
            remainingQuantities[entry.material, default: 0] += entry.quantity
            materials.remove(at: index)
            materialsPerObjectID[objectID] = materials
        }
    }
    /// Assigns location to the selected Object ID
    private func assignLocation() {
        guard let objectID = selectedObjectID else { return }
        let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            showError(message: "You must enter a valid location.")
            return
        }

        locationsPerObjectID[objectID] = location
        if var materials = materialsPerObjectID[objectID] {
            for index in materials.indices {
                materials[index].location = location
            }
            materialsPerObjectID[objectID] = materials
        }
        newLocation = ""
    }

    /// Assigns the same location to all Object IDs
    private func assignGeneralLocation() {
        let location = newGeneralLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        if location.isEmpty {
            showError(message: "You must enter a valid location.")
            return
        }

        for objectID in objectIDs {
            locationsPerObjectID[objectID] = location
            if var materials = materialsPerObjectID[objectID] {
                for index in materials.indices {
                    materials[index].location = location
                }
                materialsPerObjectID[objectID] = materials
            }
        }
        newGeneralLocation = ""
    }

    /// Checks for pending materials and generates an alert if necessary
    private func checkForMissingQuantitiesAndSendData() {
        var missingMaterialsDict: [String: Int] = [:]
        for (material, remaining) in remainingQuantities {
            if remaining > 0 {
                missingMaterialsDict[material] = remaining
            }
        }

        if !missingMaterialsDict.isEmpty {
            missingMaterials = missingMaterialsDict.map { ($0.key, $0.value) }
            activeAlert = .missingQuantities
        } else {
            sendData()
        }
    }

    /// Builds the message for the missing materials alert
    private func missingMaterialsMessage() -> String {
        var message = "The following materials are missing:\n"
        for (material, quantity) in missingMaterials {
            message += "- \(material): \(quantity)\n"
        }
        message += "\nDo you want to continue anyway?"
        return message
    }

    /// Sends the final data to the endpoint
    private func sendData() {
        var groupedMaterials: [MaterialKey: MaterialData] = [:]
        var addedQuantities: [String: Int] = [:]

        // Iterate through each Object ID to group the info
        for objectID in objectIDs {
            guard let location = locationsPerObjectID[objectID] else {
                showError(message: "Location is missing for Object ID \(objectID).")
                return
            }
            guard let materials = materialsPerObjectID[objectID], !materials.isEmpty else {
                showError(message: "No materials have been added for Object ID \(objectID).")
                return
            }

            for entry in materials {
                let key = MaterialKey(objectID: objectID, material: entry.material, location: location)
                if let existingData = groupedMaterials[key] {
                    var updatedData = existingData
                    updatedData.QUANTITY += entry.quantity
                    groupedMaterials[key] = updatedData
                } else {
                    if let trackingEntry = trackingData.first(where: { $0.material == entry.material }) {
                        let materialData = MaterialData(
                            OBJECT_ID: objectID,
                            TRACKING_NUMBER: trackingEntry.externalDeliveryID,
                            INVOICE_NUMBER: trackingEntry.externalDeliveryID,
                            MATERIAL: trackingEntry.material,
                            QUANTITY: entry.quantity,
                            LOCATION: location,
                            DELIVERY_TYPE: nil,
                            BILL: "Y",
                            UNIT: trackingEntry.unit,
                            Peso_neto: trackingEntry.pesoNeto,
                            Peso_bruto: trackingEntry.pesoBruto,
                            TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Unknown"
                        )
                        groupedMaterials[key] = materialData
                    } else {
                        showError(message: "Tracking information not found for \(entry.material).")
                        return
                    }
                }
                addedQuantities[entry.material, default: 0] += entry.quantity
            }
        }

        // Adjust the BILL property based on missing quantities
        for (material, totalQty) in totalQuantities {
            let addedQty = addedQuantities[material] ?? 0
            let isMissingQuantity = addedQty < totalQty

            for (key, var materialData) in groupedMaterials where key.material == material {
                materialData.BILL = isMissingQuantity ? "D" : "Y"
                groupedMaterials[key] = materialData
            }

            // If a material was not added at all but exists in trackingData, add it with QUANTITY = 0
            if isMissingQuantity && addedQty == 0 {
                for objectID in objectIDs {
                    guard let location = locationsPerObjectID[objectID] else {
                        showError(message: "Location is missing for \(objectID).")
                        return
                    }
                    let key = MaterialKey(objectID: objectID, material: material, location: location)
                    if groupedMaterials[key] == nil {
                        if let trackingEntry = trackingData.first(where: { $0.material == material }) {
                            let materialData = MaterialData(
                                OBJECT_ID: objectID,
                                TRACKING_NUMBER: trackingEntry.externalDeliveryID,
                                INVOICE_NUMBER: trackingEntry.externalDeliveryID,
                                MATERIAL: trackingEntry.material,
                                QUANTITY: 0,
                                LOCATION: location,
                                DELIVERY_TYPE: nil,
                                BILL: "D",
                                UNIT: trackingEntry.unit,
                                Peso_neto: trackingEntry.pesoNeto,
                                Peso_bruto: trackingEntry.pesoBruto,
                                TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Unknown"
                            )
                            groupedMaterials[key] = materialData
                        }
                    }
                }
            }
        }

        let finalData = Array(groupedMaterials.values)
        sendJSONData(finalData)
    }

    /// Sends the JSON to the server
    private func sendJSONData(_ data: [MaterialData]) {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            showError(message: "Error encoding data to JSON.")
            return
        }

        // Debug print
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("JSON to be sent:\n\(jsonString)")
        }

        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/Update"
        guard let url = URL(string: urlString) else {
            showError(message: "Invalid URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // For logging
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Code: \(httpResponse.statusCode)")
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Server Response:\n\(responseString)")
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.showError(message: "Error sending data: \(error.localizedDescription)")
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.showSuccess()
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(message: "Server response error.")
                }
            }
        }
        task.resume()
    }

    /// Shows the success alert
    private func showSuccess() {
        activeAlert = .success
    }

    /// Shows a generic error message
    private func showError(message: String) {
        errorMessage = message
        activeAlert = .error
    }

    /// Resets all local information
    private func resetData() {
        materialsPerObjectID.removeAll()
        locationsPerObjectID.removeAll()
        remainingQuantities.removeAll()
        totalQuantities.removeAll()
        scannedObjectIDs.removeAll()
        newMaterial = ""
        newQuantityText = ""
        newLocation = ""
        newGeneralLocation = ""
        missingMaterials.removeAll()
        selectedObjectID = nil
    }
}

// MARK: - Supporting Structures

struct MaterialEntry: Identifiable {
    let id: UUID
    let material: String
    var quantity: Int
    var location: String
}

struct MaterialKey: Hashable {
    let objectID: String
    let material: String
    let location: String
}

struct MaterialData: Codable {
    let OBJECT_ID: String
    let TRACKING_NUMBER: String?
    let INVOICE_NUMBER: String?
    let MATERIAL: String
    var QUANTITY: Int
    let LOCATION: String
    let DELIVERY_TYPE: String?
    var BILL: String
    var UNIT: String
    let Peso_neto: Decimal?
    let Peso_bruto: Decimal?
    let TYPE_SHIPMENT: String?
}
