import SwiftUI

struct MaterialChecklistView: View {
    // Aquí accedemos al valor global ("Inbond" / "Domestic")
    @EnvironmentObject var shipmentState: ShipmentState
    
    var trackingData: [TrackingData] // Provided tracking data
    var objectIDs: [String] // List of object IDs

    // States to manage materials and locations
    @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
    @State private var locationsPerObjectID: [String: String] = [:]

    // States to manage remaining and total quantities of each material
    @State private var remainingQuantities: [String: Int] = [:]
    @State private var totalQuantities: [String: Int] = [:] // Added to track total quantities

    // States to control the presentation of sheets and alerts
    @State private var showingAddMaterialSheet = false
    @State private var selectedObjectID: String?
    @State private var newMaterial = ""
    @State private var newQuantityText = ""

    // State variables for alerts
    enum ActiveAlert: Identifiable {
        case error
        case success
        case missingQuantities

        var id: Int {
            hashValue
        }
    }
    @State private var activeAlert: ActiveAlert?
    @State private var errorMessage: String = ""
    @State private var missingMaterials: [(material: String, quantity: Int)] = []

    // States for location assignment
    @State private var showingAssignLocationSheet = false
    @State private var newLocation = ""

    // State for general location assignment
    @State private var showingAssignGeneralLocationSheet = false
    @State private var newGeneralLocation = ""

    // States for scanning
    @State private var showingMaterialScanner = false
    @State private var showingQuantityScanner = false

    // State for object ID scanning
    @State private var scannedObjectIDs: Set<String> = []
    @State private var showingObjectIDScanner = false

    // State to manage expandable/collapsible object IDs
    @State private var expandedObjectIDs: [String: Bool] = [:]

    // Environment variable to handle view dismissal
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Ejemplo de uso de la variable global
            Text("Type of Shipment \(shipmentState.selectedInboundType ?? "N/A")")
                .font(.headline)
                .padding()

            // Resto de la vista...
            List {
                ForEach(objectIDs, id: \.self) { objectID in
                    DisclosureGroup(
                        isExpanded: Binding<Bool>(
                            get: { expandedObjectIDs[objectID, default: false] },
                            set: { expandedObjectIDs[objectID] = $0 }
                        )
                    ) {
                        if !scannedObjectIDs.contains(objectID) {
                            Button(action: {
                                selectedObjectID = objectID
                                showingObjectIDScanner = true
                            }) {
                                Text("Scan Object ID")
                                    .foregroundColor(.orange)
                            }
                        } else {
                            if let location = locationsPerObjectID[objectID] {
                                HStack {
                                    Text("Assigned Location:")
                                    Spacer()
                                    Text(location)
                                        .fontWeight(.bold)
                                }
                            }

                            Button(action: {
                                selectedObjectID = objectID
                                showingAssignLocationSheet = true
                            }) {
                                Text(locationsPerObjectID[objectID] != nil ? "Change Location" : "Assign Location")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 5)

                            if let materials = materialsPerObjectID[objectID] {
                                ForEach(materials) { entry in
                                    HStack {
                                        Text("Material: \(entry.material)")
                                        Spacer()
                                        Text("Quantity: \(entry.quantity)")
                                    }
                                }
                                .onDelete { indices in
                                    deleteMaterials(at: indices, for: objectID)
                                }
                            }

                            Button(action: {
                                selectedObjectID = objectID
                                showingAddMaterialSheet = true
                            }) {
                                Text("Add Material")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                            .disabled(!scannedObjectIDs.contains(objectID))
                        }
                    } label: {
                        Text("Object ID: \(objectID)")
                            .font(.headline)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .padding(.bottom)

            Button(action: {
                showingAssignGeneralLocationSheet = true
            }) {
                Text("Assign Location to All")
                    .foregroundColor(.purple)
            }
            .padding()

            VStack(alignment: .leading) {
                Text("Remaining Quantities:")
                    .font(.headline)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(remainingQuantities.keys.filter { remainingQuantities[$0]! > 0 }.sorted(), id: \.self) { material in
                            VStack {
                                Text(material)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Remaining: \(remainingQuantities[material]!)")
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)
            }

            Spacer()

            Button(action: {
                checkForMissingQuantitiesAndSendData()
            }) {
                Text("Send")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Packing List Checklist")
        .onAppear {
            initializeRemainingQuantities()
            for objectID in objectIDs {
                expandedObjectIDs[objectID] = true
            }
        }
        // Assign Location Sheet
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
        // Add Material Sheet
        .sheet(isPresented: $showingAddMaterialSheet) {
            VStack {
                Text("Add Material")
                    .font(.headline)
                    .padding()

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

                List {
                    ForEach(trackingDataMaterials(), id: \.self) { material in
                        Button(action: {
                            newMaterial = material
                        }) {
                            Text(material)
                        }
                    }
                }
                .frame(maxHeight: 150)

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
                }
            }
            .padding()
            // Present scanner sheets
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
            }
        }
        // General Assign Location Sheet
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
        // Object ID Scanner Sheet
        .sheet(isPresented: $showingObjectIDScanner) {
            let scannedCodeBinding = Binding<String?>(
                get: { "" },
                set: { _ in }
            )
            CameraScannerWrapperView(scannedCode: scannedCodeBinding) { code in
                if code == selectedObjectID {
                    if let validCode = selectedObjectID {
                        scannedObjectIDs.insert(validCode)
                    } else {
                        showError(message: "Selected Object ID is nil.")
                    }
                } else {
                    showError(message: "Scanned code does not match Object ID.")
                }
                showingObjectIDScanner = false
            }
        }
    }

    // Funciones internas (sin cambios sustanciales):
    func initializeRemainingQuantities() {
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

    func trackingDataMaterials() -> [String] {
        let materials = trackingData.map { $0.material }
        return Array(Set(materials)).sorted()
    }

    func addMaterial() {
        guard let objectID = selectedObjectID else { return }
        let material = newMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityStr = newQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)

        if material.isEmpty || quantityStr.isEmpty {
            showError(message: "Please fill in all fields.")
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

    func deleteMaterials(at offsets: IndexSet, for objectID: String) {
        if var materials = materialsPerObjectID[objectID] {
            for index in offsets {
                let entry = materials[index]
                if let remaining = remainingQuantities[entry.material] {
                    remainingQuantities[entry.material] = remaining + entry.quantity
                } else {
                    remainingQuantities[entry.material] = entry.quantity
                }
            }
            materials.remove(atOffsets: offsets)
            materialsPerObjectID[objectID] = materials
        }
    }

    func assignLocation() {
        guard let objectID = selectedObjectID else { return }
        let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            showError(message: "Please enter a location.")
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

    func assignGeneralLocation() {
        let location = newGeneralLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            showError(message: "Please enter a location.")
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

    func showError(message: String) {
        errorMessage = message
        activeAlert = .error
    }

    func checkForMissingQuantitiesAndSendData() {
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

    func missingMaterialsMessage() -> String {
        var message = "The following quantities are missing:\n"
        for (material, quantity) in missingMaterials {
            message += "- \(material): \(quantity)\n"
        }
        message += "\nDo you want to continue?"
        return message
    }

    func sendData() {
        var groupedMaterials: [MaterialKey: MaterialData] = [:]
        var addedQuantities: [String: Int] = [:]

        for objectID in objectIDs {
            guard let location = locationsPerObjectID[objectID] else {
                showError(message: "Missing location for Object ID \(objectID).")
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
                            TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Uknown"
                        )
                        groupedMaterials[key] = materialData
                    } else {
                        showError(message: "No tracking information found for material \(entry.material).")
                        return
                    }
                }
                addedQuantities[entry.material, default: 0] += entry.quantity
            }
        }

        for (material, totalQty) in totalQuantities {
            let addedQty = addedQuantities[material] ?? 0
            let isMissingQuantity = addedQty < totalQty

            for (key, var materialData) in groupedMaterials where key.material == material {
                materialData.BILL = isMissingQuantity ? "D" : "Y"
                groupedMaterials[key] = materialData
            }

            if isMissingQuantity && addedQty == 0 {
                for objectID in objectIDs {
                    guard let location = locationsPerObjectID[objectID] else {
                        showError(message: "Missing location for Object ID \(objectID).")
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
                                TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Uknown"
                            )
                            groupedMaterials[key] = materialData
                        }
                    }
                }
            }
        }

        let jsonDataArray = Array(groupedMaterials.values)
        sendJSONData(jsonDataArray)
    }

    func sendJSONData(_ data: [MaterialData]) {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            showError(message: "Error encoding data to JSON.")
            return
        }

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("JSON Data being sent:\n\(jsonString)")
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
            if let httpResponse = response as? HTTPURLResponse {
                print("API Response Status Code: \(httpResponse.statusCode)")
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("API Response Body:\n\(responseString)")
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
                    self.showError(message: "Error in server response.")
                }
            }
        }
        task.resume()
    }

    func showSuccess() {
        activeAlert = .success
    }

    func resetData() {
        materialsPerObjectID.removeAll()
        locationsPerObjectID.removeAll()
        remainingQuantities.removeAll()
        totalQuantities.removeAll()
        scannedObjectIDs.removeAll()
        expandedObjectIDs.removeAll()
        newMaterial = ""
        newQuantityText = ""
        newLocation = ""
        newGeneralLocation = ""
        missingMaterials.removeAll()
    }
}

// MARK: - MaterialEntry, MaterialKey, MaterialData
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
    let Peso_neto : Decimal?
    let Peso_bruto : Decimal?
    let TYPE_SHIPMENT: String?
}
