import SwiftUI

// MARK: - Ejemplo de modelos
struct MaterialEntry: Identifiable {
    let id: UUID
    let material: String
    var quantity: Int
    var location: String
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
    let VENDOR: String?
}



// MARK: - Vista principal
struct MaterialChecklistView: View {
    @EnvironmentObject var shipmentState: ShipmentState
    
    var trackingData: [TrackingData]
    var objectIDs: [String]

    @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
    @State private var locationsPerObjectID: [String: String] = [:]
    @State private var remainingQuantities: [String: Int] = [:]
    @State private var totalQuantities: [String: Int] = [:]

    // Para la selección de Object ID
    @State private var selectedObjectID: String?
    // Conjunto de Object IDs escaneados/validados
    @State private var scannedObjectIDs: Set<String> = []

    // Ubicaciones
    @State private var newLocation = ""
    @State private var newGeneralLocation = ""

    // Sheets
    @State private var showingAssignLocationSheet = false
    @State private var showingAssignGeneralLocationSheet = false
    @State private var showingObjectIDScanner = false
    @State private var showingMultiMaterialSheet = false
    
    // Sheet para distribuir un solo material a todos los ObjectIDs
    @State private var showingSingleMaterialDistribution = false

    // Alertas
    enum ActiveAlert: Identifiable {
        case error
        case success
        case missingQuantities
        case confirm

        var id: Int { self.hashValue }
    }
    @State private var activeAlert: ActiveAlert?
    @State private var errorMessage: String = ""
    @State private var missingMaterials: [(material: String, quantity: Int)] = []

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // 1. Info general
                Section(header: Text("Shipment Information")) {
                    Text("Shipment Type: \(shipmentState.selectedInboundType ?? "N/A")")
                        .font(.headline)
                }

                // 2. Selector o botón de escanear Object ID
                Section(header: Text("Select an Object ID")) {
                    if objectIDs.count <= 10 {
                        // Mostrar Picker si hay <=10
                        Picker("Object ID", selection: $selectedObjectID) {
                            Text("Choose...").tag(String?.none)
                            ForEach(objectIDs, id: \.self) { objectID in
                                Text(objectID).tag(Optional(objectID))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        // Botón escanear
                        Button {
                            showingObjectIDScanner = true
                        } label: {
                            Label("Scan Object ID", systemImage: "qrcode.viewfinder")
                                .foregroundColor(.orange)
                        }
                    } else {
                        // Si >10, sólo escanear
                        Button {
                            showingObjectIDScanner = true
                        } label: {
                            Label("Scan Object ID", systemImage: "qrcode.viewfinder")
                                .foregroundColor(.orange)
                        }
                    }
                }

                // 3. Detalles del ObjectID seleccionado
                if let objectID = selectedObjectID {
                    Section(header: Text("Details of \(objectID)")) {
                        if objectIDs.count <= 10 {
                            // Para <=10, el usuario ya eligió en el Picker,
                            // pero también debe escanear para validarlo
                            if !scannedObjectIDs.contains(objectID) {
                                Text("This Object ID is not yet validated. Please scan to start adding materials.")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            } else {
                                // Ya validado
                                detailsForValidatedObjectID(objectID)
                            }
                        } else {
                            // Para >10, se asigna tras escanear
                            detailsForValidatedObjectID(objectID)
                        }
                    }
                }

                // 4. Asignar ubicación global
                Section {
                    Button {
                        showingAssignGeneralLocationSheet = true
                    } label: {
                        Label("Assign Location to All", systemImage: "location.fill")
                            .foregroundColor(.purple)
                    }
                }

                // 5. Cantidades restantes
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
                
                // 6. Si sólo hay 1 material pendiente, muestra un botón para distribuir
                if trackingDataMaterials().count == 1,
                   let singleMaterial = trackingDataMaterials().first {
                    Section {
                        Button {
                            showingSingleMaterialDistribution = true
                        } label: {
                            Label(
                                "Distribute \"\(singleMaterial)\" across Object IDs",
                                systemImage: "square.stack.3d.up"
                            )
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Packing List Checklist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeAlert = .confirm
                    } label: {
                        Text("Send")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            initializeRemainingQuantities()
        }
        // MARK: Sheets
        .sheet(isPresented: $showingAssignLocationSheet) {
            // ... Aquí tu cámara o tu UI para leer una ubicación
            // Suponiendo que al final asignas a `newLocation`
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
        .sheet(isPresented: $showingObjectIDScanner) {
            let scannedCodeBinding = Binding<String?>(
                get: { "" },
                set: { _ in }
            )
            CameraScannerWrapperView(scannedCode: scannedCodeBinding) { code in
                // Lógica para <=10 y >10
                if objectIDs.count <= 10 {
                    if let current = selectedObjectID {
                        if code == current {
                            scannedObjectIDs.insert(current)
                        } else {
                            showError(message: "Scanned code (\(code)) does not match selected \(current).")
                        }
                    } else {
                        showError(message: "No Object ID has been selected.")
                    }
                } else {
                    if objectIDs.contains(code) {
                        selectedObjectID = code
                        scannedObjectIDs.insert(code)
                    } else {
                        showError(message: "Scanned code (\(code)) is not in the valid list of Object IDs.")
                    }
                }
                showingObjectIDScanner = false
            }
        }
        // Vista de agregar múltiples materiales (en orden)
        .sheet(isPresented: $showingMultiMaterialSheet) {
            if let objectID = selectedObjectID {
                MultipleMaterialSelectionView(
                    availableMaterials: trackingDataMaterials(),
                    remainingQuantities: remainingQuantities
                ) { results in
                    // results es un [(material, quantity)] en orden
                    for (material, quantity) in results {
                        addMaterial(objectID: objectID, material: material, quantity: quantity)
                    }
                }
            }
        }
        // Distribución de un solo material
        .sheet(isPresented: $showingSingleMaterialDistribution) {
            if trackingDataMaterials().count == 1,
               let singleMaterial = trackingDataMaterials().first {
                let remain = remainingQuantities[singleMaterial, default: 0]
                SingleMaterialDistributionView(
                    material: singleMaterial,
                    objectIDs: objectIDs,
                    maxRemaining: remain
                ) { distribution in
                    // distribution es [ObjectID: Int]
                    for (objID, qty) in distribution {
                        if qty > 0 {
                            addMaterial(objectID: objID, material: singleMaterial, quantity: qty)
                        }
                    }
                }
            }
        }
        // MARK: - Alerts
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
                        sendData(billAllAsD: true)
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            case .confirm:
                return Alert(
                    title: Text("Are you sure?"),
                    message: Text("Do you want to send this data?"),
                    primaryButton: .destructive(Text("Send")) {
                        checkForMissingQuantitiesAndSendData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: Sub-View: detalles para un ObjectID validado
    @ViewBuilder
    private func detailsForValidatedObjectID(_ objectID: String) -> some View {
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

        // Lista de materiales agregados (en orden)
        if let materials = materialsPerObjectID[objectID], !materials.isEmpty {
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
                            Button(role: .destructive) {
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

        // Botón para agregar varios materiales
        Button {
            showingMultiMaterialSheet = true
        } label: {
            Label("Add Multiple Materials", systemImage: "plus")
                .foregroundColor(.blue)
        }
    }

    // MARK: - Funciones internas
    private func initializeRemainingQuantities() {
        // Sumamos la cantidad total esperada por material
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
        let allMaterials = trackingData.map { $0.material }
        return Array(Set(allMaterials))
            .filter { remainingQuantities[$0, default: 0] > 0 }
            .sorted()
    }

    private func addMaterial(objectID: String, material: String, quantity: Int) {
        guard quantity > 0 else {
            showError(message: "Quantity for \(material) must be greater than zero.")
            return
        }

        if let remaining = remainingQuantities[material], remaining >= quantity {
            remainingQuantities[material] = remaining - quantity
            let location = locationsPerObjectID[objectID] ?? ""
            let entry = MaterialEntry(
                id: UUID(),
                material: material,
                quantity: quantity,
                location: location
            )
            materialsPerObjectID[objectID, default: []].append(entry)
        } else {
            showError(message: "Insufficient quantity for material \(material).")
        }
    }

    private func deleteMaterial(_ entry: MaterialEntry, for objectID: String) {
        if var materials = materialsPerObjectID[objectID],
           let index = materials.firstIndex(where: { $0.id == entry.id }) {
            // Devolvemos la cantidad
            remainingQuantities[entry.material, default: 0] += entry.quantity
            materials.remove(at: index)
            materialsPerObjectID[objectID] = materials
        }
    }

    private func assignLocation() {
        guard let objectID = selectedObjectID else { return }
        let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            showError(message: "You must enter a valid location.")
            return
        }

        locationsPerObjectID[objectID] = location

        // Actualizar la location de los materiales que ya estén
        if var materials = materialsPerObjectID[objectID] {
            for index in materials.indices {
                materials[index].location = location
            }
            materialsPerObjectID[objectID] = materials
        }
        newLocation = ""
    }

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
            sendData(billAllAsD: false)
        }
    }

    private func missingMaterialsMessage() -> String {
        var message = "The following materials still have missing quantities:\n"
        for (material, quantity) in missingMaterials {
            message += "- \(material): \(quantity)\n"
        }
        message += "\nDo you want to continue anyway?"
        return message
    }

    /// Envía el JSON, con la opción de forzar todo a "D" si hay faltantes.
    private func sendData(billAllAsD: Bool) {
        // 1) Construimos el array final, en el mismo orden que el usuario fue agregando
        var finalData: [MaterialData] = []
        
        // Para llevar control de cuánto agregamos de cada material
        var addedQuantities: [String: Int] = [:]
        
        // Recorremos cada objectID en orden (si quieres un orden distinto, ajusta aquí)
        for objectID in objectIDs {
            // Primero revisamos la ubicación
            guard let location = locationsPerObjectID[objectID] else {
                showError(message: "Location is missing for Object ID \(objectID).")
                return
            }
            // Si no tiene materiales, se avisa
            guard let materialList = materialsPerObjectID[objectID], !materialList.isEmpty else {
                showError(message: "No materials have been added for Object ID \(objectID).")
                return
            }
            
            // Cada entrada se convierte en un MaterialData
            for entry in materialList {
                guard let track = trackingData.first(where: { $0.material == entry.material }) else {
                    showError(message: "Tracking information not found for \(entry.material).")
                    return
                }
                
                let newItem = MaterialData(
                    OBJECT_ID: objectID,
                    TRACKING_NUMBER: track.externalDeliveryID,
                    INVOICE_NUMBER: track.externalDeliveryID,
                    MATERIAL: entry.material,
                    QUANTITY: entry.quantity,
                    LOCATION: location,
                    DELIVERY_TYPE: nil,
                    BILL: "Y",   // valor temporal, se ajusta más abajo
                    UNIT: track.unit,
                    Peso_neto: track.pesoNeto,
                    Peso_bruto: track.pesoBruto,
                    TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Unknown",
                    VENDOR: track.supplierName
                    
                )
                finalData.append(newItem)
                
                // Sumamos lo añadido para luego ver si hay faltante
                addedQuantities[entry.material, default: 0] += entry.quantity
            }
        }
        
        // 2) Ajustar BILL según falten cantidades
        if billAllAsD {
            // Forzamos "D" a todos
            for i in 0..<finalData.count {
                finalData[i].BILL = "D"
            }
        } else {
            // Marcamos "D" a aquellos materiales donde no se cumplió la cantidad total
            for (material, totalQty) in totalQuantities {
                let sumAdded = addedQuantities[material] ?? 0
                let faltante = (sumAdded < totalQty)
                
                if faltante {
                    // Poner "D" en todas las entradas de ese material
                    for i in 0..<finalData.count {
                        if finalData[i].MATERIAL == material {
                            finalData[i].BILL = "D"
                        }
                    }
                }
                
                // Si un material no se agregó NADA (sumAdded == 0),
                // y quieres meter una línea "dummy" con qty=0 y BILL=D, lo haríamos así:
                if faltante && sumAdded == 0 {
                    // Podemos decidir si se agrega una línea por *cada* objectID
                    // o sólo una. Aquí lo haremos por cada objectID para ser consistente.
                    for objectID in objectIDs {
                        guard let location = locationsPerObjectID[objectID] else {
                            showError(message: "Location missing for \(objectID).")
                            return
                        }
                        if let track = trackingData.first(where: { $0.material == material }) {
                            let dummy = MaterialData(
                                OBJECT_ID: objectID,
                                TRACKING_NUMBER: track.externalDeliveryID,
                                INVOICE_NUMBER: track.externalDeliveryID,
                                MATERIAL: track.material,
                                QUANTITY: 0,
                                LOCATION: location,
                                DELIVERY_TYPE: nil,
                                BILL: "D",
                                UNIT: track.unit,
                                Peso_neto: track.pesoNeto,
                                Peso_bruto: track.pesoBruto,
                                TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Unknown",
                                VENDOR: track.supplierName
                            )
                            finalData.append(dummy)
                        }
                    }
                }
            }
        }
        
        // 3) Convertir a JSON y enviar
        sendJSONData(finalData)
    }

    private func sendJSONData(_ data: [MaterialData]) {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            showError(message: "Error encoding data to JSON.")
            return
        }

        // DEBUG
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

            // Asumimos 200 como éxito
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

    private func showSuccess() {
        activeAlert = .success
    }

    private func showError(message: String) {
        errorMessage = message
        activeAlert = .error
    }

    private func resetData() {
        materialsPerObjectID.removeAll()
        locationsPerObjectID.removeAll()
        remainingQuantities.removeAll()
        totalQuantities.removeAll()
        scannedObjectIDs.removeAll()
        newLocation = ""
        newGeneralLocation = ""
        missingMaterials.removeAll()
        selectedObjectID = nil
    }
}

// MARK: - MultipleMaterialSelectionView
struct MultipleMaterialSelectionView: View {
    var availableMaterials: [String]
    var remainingQuantities: [String: Int]
    
    /// Devolveremos un array de tuplas (material, cantidad) en orden
    var onCompletion: ([(String, Int)]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var step = 1
    
    // Ahora es un Array, no un Set
    @State private var selectedMaterials: [String] = []
    @State private var quantitiesForSelected: [String: String] = [:]
    @State private var searchText = ""

    var filteredMaterials: [String] {
        if searchText.isEmpty {
            return availableMaterials
        } else {
            return availableMaterials.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if step == 1 {
                    Text("Select Materials")
                        .font(.headline)
                        .padding()

                    // Buscador
                    HStack {
                        TextField("Search materials...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    // Lista de toggles
                    List(filteredMaterials, id: \.self) { material in
                        HStack {
                            Text(material)
                            Spacer()
                            Text("Max: \(remainingQuantities[material, default: 0])")
                                .font(.footnote)
                                .foregroundColor(.gray)
                            Toggle("", isOn: Binding(
                                get: {
                                    selectedMaterials.contains(material)
                                },
                                set: { newValue in
                                    if newValue {
                                        // Agregar al final si no estaba
                                        if !selectedMaterials.contains(material) {
                                            selectedMaterials.append(material)
                                        }
                                    } else {
                                        // Remover si estaba
                                        if let idx = selectedMaterials.firstIndex(of: material) {
                                            selectedMaterials.remove(at: idx)
                                        }
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }

                    Button("Continue") {
                        if !selectedMaterials.isEmpty {
                            step = 2
                            // Inicializar cantidades
                            for mat in selectedMaterials {
                                quantitiesForSelected[mat] = ""
                            }
                        }
                    }
                    .padding()
                    .disabled(selectedMaterials.isEmpty)

                } else {
                    Text("Enter Quantities")
                        .font(.headline)
                        .padding()

                    List(selectedMaterials, id: \.self) { material in
                        HStack {
                            Text(material)
                            Spacer()
                            TextField("Quantity", text: Binding(
                                get: { quantitiesForSelected[material] ?? "" },
                                set: { quantitiesForSelected[material] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                        }
                    }

                    HStack {
                        Button("Back") {
                            step = 1
                        }
                        .padding()

                        Spacer()

                        Button("Add All") {
                            // Construimos un array de pares
                            var finalArray: [(String, Int)] = []
                            for mat in selectedMaterials {
                                let textQty = quantitiesForSelected[mat] ?? "0"
                                let intQty = Int(textQty) ?? 0
                                finalArray.append((mat, intQty))
                            }
                            onCompletion(finalArray)
                            dismiss()
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Add Multiple Materials", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - SingleMaterialDistributionView
struct SingleMaterialDistributionView: View {
    let material: String
    let objectIDs: [String]
    let maxRemaining: Int
    
    /// Closure llamado cuando el usuario termina
    var onDone: ([String: Int]) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var quantities: [String: String] = [:]
    
    private var totalAllocated: Int {
        quantities.values.compactMap(Int.init).reduce(0, +)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Distribute \(material)")) {
                    Text("Remaining: \(maxRemaining)")
                        .font(.headline)
                    Text("Allocated: \(totalAllocated)")
                        .font(.subheadline)
                }
                
                Section {
                    Button("Auto Distribute Evenly") {
                        autoDistribute()
                    }
                }
                
                Section(header: Text("Quantities per Object ID")) {
                    ForEach(objectIDs, id: \.self) { objID in
                        HStack {
                            Text(objID)
                            Spacer()
                            TextField("Qty", text: Binding(
                                get: { quantities[objID] ?? "" },
                                set: { quantities[objID] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        }
                    }
                }
            }
            .navigationBarTitle("Distribute Material", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        guard totalAllocated <= maxRemaining else {
                            // Aquí podrías mostrar un alert si excede la cantidad
                            return
                        }
                        // Armamos el diccionario de distribución
                        var distribution: [String: Int] = [:]
                        for objID in objectIDs {
                            let qty = Int(quantities[objID] ?? "0") ?? 0
                            distribution[objID] = qty
                        }
                        
                        onDone(distribution)
                        dismiss()
                    }
                }
            }
            .onAppear {
                for objID in objectIDs {
                    quantities[objID] = ""
                }
            }
        }
    }
    
    private func autoDistribute() {
        let count = objectIDs.count
        guard count > 0 else { return }
        
        let each = maxRemaining / count
        let remainder = maxRemaining % count
        
        for i in 0..<count {
            let objID = objectIDs[i]
            var value = each
            if i < remainder {
                value += 1
            }
            quantities[objID] = "\(value)"
        }
    }
}


//


/*  import SwiftUI
 
 // MARK: - Example Models

 /// Structure to handle the info of each material added to an ObjectID.
 struct MaterialEntry: Identifiable {
     let id: UUID
     let material: String
     var quantity: Int
     var location: String
 }

 /// Key to group materials that share the same objectID, material, and location.
 struct MaterialKey: Hashable {
     let objectID: String
     let material: String
     let location: String
 }

 /// Structure to send to the server via JSON.
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

 // MARK: - Main View

 struct MaterialChecklistView: View {
     @EnvironmentObject var shipmentState: ShipmentState
     
     // Data for tracking and the list of objectIDs you receive from your API or logic
     var trackingData: [TrackingData]
     var objectIDs: [String]

     // Dictionaries to store UI-captured info
     @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
     @State private var locationsPerObjectID: [String: String] = [:]
     @State private var remainingQuantities: [String: Int] = [:]
     @State private var totalQuantities: [String: Int] = [:]

     // Selection control for ObjectID
     @State private var selectedObjectID: String?
     // To mark an ObjectID as scanned/validated
     @State private var scannedObjectIDs: Set<String> = []

     // For location assignments
     @State private var newLocation = ""
     @State private var newGeneralLocation = ""

     // Sheet states
     @State private var showingAssignLocationSheet = false
     @State private var showingAssignGeneralLocationSheet = false
     @State private var showingObjectIDScanner = false

     // NEW: Sheet for multi-material selection
     @State private var showingMultiMaterialSheet = false

     // Alert handling
     enum ActiveAlert: Identifiable {
         case error
         case success
         case missingQuantities
         case confirm

         var id: Int { self.hashValue }
     }
     @State private var activeAlert: ActiveAlert?
     @State private var errorMessage: String = ""
     @State private var missingMaterials: [(material: String, quantity: Int)] = []

     // To dismiss the current view if needed
     @Environment(\.dismiss) var dismiss

     var body: some View {
         NavigationView {
             Form {
                 // 1. General shipment info
                 Section(header: Text("Shipment Information")) {
                     Text("Shipment Type: \(shipmentState.selectedInboundType ?? "N/A")")
                         .font(.headline)
                 }

                 // 2. ObjectID Selection
                 Section(header: Text("Select an Object ID")) {
                     Picker("Object ID", selection: $selectedObjectID) {
                         Text("Choose...").tag(String?.none)
                         ForEach(objectIDs, id: \.self) { objectID in
                             Text(objectID).tag(Optional(objectID))
                         }
                     }
                     .pickerStyle(MenuPickerStyle())
                 }

                 // 3. Details for the selected ObjectID
                 if let objectID = selectedObjectID {
                     Section(header: Text("Details of \(objectID)")) {
                         // Show "Scan" button if not validated
                         if !scannedObjectIDs.contains(objectID) {
                             Button {
                                 showingObjectIDScanner = true
                             } label: {
                                 Label("Scan Object ID", systemImage: "qrcode.viewfinder")
                                     .foregroundColor(.orange)
                             }

                         } else {
                             // Show assigned location or "assign" button
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

                             // List of materials added to this ObjectID
                             if let materials = materialsPerObjectID[objectID], !materials.isEmpty {
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
                                                 // Button to remove that material
                                                 Button(role: .destructive) {
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

                             // Button to add multiple materials in one go
                             Button {
                                 showingMultiMaterialSheet = true
                             } label: {
                                 Label("Add Multiple Materials", systemImage: "plus")
                                     .foregroundColor(.blue)
                             }
                             .disabled(!scannedObjectIDs.contains(objectID) || trackingDataMaterials().isEmpty)
                         }
                     }
                 }

                 // 4. Assign a global location to ALL ObjectIDs
                 Section {
                     Button {
                         showingAssignGeneralLocationSheet = true
                     } label: {
                         Label("Assign Location to All", systemImage: "location.fill")
                             .foregroundColor(.purple)
                     }
                 }

                 // 5. Display remaining quantities per material
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
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         // "Send" is pressed -> show confirm alert
                         activeAlert = .confirm
                     } label: {
                         Text("Send")
                             .padding()
                             .background(Color.blue)
                             .foregroundColor(.white)
                             .cornerRadius(8)
                     }
                 }
             }
         }
         .onAppear {
             initializeRemainingQuantities()
         }
         // MARK: - Sheets
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
         // NEW: Sheet for multiple materials
         .sheet(isPresented: $showingMultiMaterialSheet) {
             if let objectID = selectedObjectID {
                 MultipleMaterialSelectionView(
                     availableMaterials: trackingDataMaterials(),
                     remainingQuantities: remainingQuantities
                 ) { results in
                     // `results` is a dictionary [material: enteredQuantity]
                     for (material, quantity) in results {
                         addMaterial(objectID: objectID, material: material, quantity: quantity)
                     }
                 }
             }
         }
         // MARK: - Alerts
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
                     message: Text("Do you want to send this data?"),
                     primaryButton: .destructive(Text("Send")) {
                         checkForMissingQuantitiesAndSendData()
                     },
                     secondaryButton: .cancel()
                 )
             }
         }
     }

     // MARK: - Business Logic

     /// Initialize total and remaining quantities from `trackingData`.
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

     /// Returns the list of materials that still have > 0 quantity remaining.
     private func trackingDataMaterials() -> [String] {
         let allMaterials = trackingData.map { $0.material }
         // Filter out those that have zero remaining quantity, if desired
         // For now, we just return all unique materials
         return Array(Set(allMaterials))
             .filter { remainingQuantities[$0, default: 0] > 0 }
             .sorted()
     }

     /// Add a given material (with quantity) to a specific objectID.
     private func addMaterial(objectID: String, material: String, quantity: Int) {
         guard quantity > 0 else {
             showError(message: "Quantity for \(material) must be greater than zero.")
             return
         }

         // Check if there is enough quantity remaining
         if let remaining = remainingQuantities[material], remaining >= quantity {
             remainingQuantities[material] = remaining - quantity
             // Use the same location assigned to this objectID, if it exists
             let location = locationsPerObjectID[objectID] ?? ""
             let entry = MaterialEntry(id: UUID(), material: material, quantity: quantity, location: location)
             materialsPerObjectID[objectID, default: []].append(entry)
         } else {
             showError(message: "Insufficient quantity for material \(material).")
         }
     }

     /// Delete a material from a particular objectID, returning quantity to local inventory.
     private func deleteMaterial(_ entry: MaterialEntry, for objectID: String) {
         if var materials = materialsPerObjectID[objectID],
            let index = materials.firstIndex(where: { $0.id == entry.id }) {
             remainingQuantities[entry.material, default: 0] += entry.quantity
             materials.remove(at: index)
             materialsPerObjectID[objectID] = materials
         }
     }

     /// Assigns a location to the currently selected objectID.
     private func assignLocation() {
         guard let objectID = selectedObjectID else { return }
         let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

         if location.isEmpty {
             showError(message: "You must enter a valid location.")
             return
         }

         locationsPerObjectID[objectID] = location
         // Update location in any materials already assigned
         if var materials = materialsPerObjectID[objectID] {
             for index in materials.indices {
                 materials[index].location = location
             }
             materialsPerObjectID[objectID] = materials
         }
         newLocation = ""
     }

     /// Assigns the same location to ALL objectIDs.
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

     /// Checks if there are materials with missing quantities before sending.
     private func checkForMissingQuantitiesAndSendData() {
         var missingMaterialsDict: [String: Int] = [:]
         for (material, remaining) in remainingQuantities {
             if remaining > 0 {
                 missingMaterialsDict[material] = remaining
             }
         }

         if !missingMaterialsDict.isEmpty {
             // There are materials not fully accounted for
             missingMaterials = missingMaterialsDict.map { ($0.key, $0.value) }
             activeAlert = .missingQuantities
         } else {
             // All materials accounted for; send immediately
             sendData()
         }
     }

     /// Message to display in the "missing materials" alert.
     private func missingMaterialsMessage() -> String {
         var message = "The following materials still have missing quantities:\n"
         for (material, quantity) in missingMaterials {
             message += "- \(material): \(quantity)\n"
         }
         message += "\nDo you want to continue anyway?"
         return message
     }

     /// Gather final data and send it to the server.
     private func sendData() {
         // Group materials that share (objectID, material, location)
         var groupedMaterials: [MaterialKey: MaterialData] = [:]
         var addedQuantities: [String: Int] = [:]

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
                 
                 if var existingData = groupedMaterials[key] {
                     existingData.QUANTITY += entry.quantity
                     groupedMaterials[key] = existingData
                 } else {
                     if let trackingEntry = trackingData.first(where: { $0.material == entry.material }) {
                         let newData = MaterialData(
                             OBJECT_ID: objectID,
                             TRACKING_NUMBER: trackingEntry.externalDeliveryID,
                             INVOICE_NUMBER: trackingEntry.externalDeliveryID,
                             MATERIAL: trackingEntry.material,
                             QUANTITY: entry.quantity,
                             LOCATION: location,
                             DELIVERY_TYPE: nil,    // Adjust according to your needs
                             BILL: "Y",
                             UNIT: trackingEntry.unit,
                             Peso_neto: trackingEntry.pesoNeto,
                             Peso_bruto: trackingEntry.pesoBruto,
                             TYPE_SHIPMENT: shipmentState.selectedInboundType ?? "Unknown"
                         )
                         groupedMaterials[key] = newData
                     } else {
                         showError(message: "Tracking information not found for \(entry.material).")
                         return
                     }
                 }
                 // Keep a total count of how many have been added per material
                 addedQuantities[entry.material, default: 0] += entry.quantity
             }
         }

         // Adjust the `BILL` field based on whether each material is missing quantities
         for (material, totalQty) in totalQuantities {
             let addedQty = addedQuantities[material] ?? 0
             let isMissingQuantity = (addedQty < totalQty)

             // Mark `BILL = "D"` if there's a shortage
             for (key, var materialData) in groupedMaterials where key.material == material {
                 materialData.BILL = isMissingQuantity ? "D" : "Y"
                 groupedMaterials[key] = materialData
             }

             // If a material was never added at all (addedQty == 0), include it with QUANTITY=0 and BILL="D"
             if isMissingQuantity && addedQty == 0 {
                 for objectID in objectIDs {
                     guard let location = locationsPerObjectID[objectID] else {
                         showError(message: "Location is missing for \(objectID).")
                         return
                     }
                     let key = MaterialKey(objectID: objectID, material: material, location: location)
                     if groupedMaterials[key] == nil {
                         if let trackingEntry = trackingData.first(where: { $0.material == material }) {
                             let missingData = MaterialData(
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
                             groupedMaterials[key] = missingData
                         }
                     }
                 }
             }
         }

         // Convert to array and encode to JSON
         let finalData = Array(groupedMaterials.values)
         sendJSONData(finalData)
     }

     /// Sends the JSON data via PUT (or the method you need).
     private func sendJSONData(_ data: [MaterialData]) {
         guard let jsonData = try? JSONEncoder().encode(data) else {
             showError(message: "Error encoding data to JSON.")
             return
         }

         // DEBUG
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

             // Assume 200 status code means success
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

     /// Show success alert
     private func showSuccess() {
         activeAlert = .success
     }

     /// Show error alert
     private func showError(message: String) {
         errorMessage = message
         activeAlert = .error
     }

     /// Reset data for a fresh start (optional)
     private func resetData() {
         materialsPerObjectID.removeAll()
         locationsPerObjectID.removeAll()
         remainingQuantities.removeAll()
         totalQuantities.removeAll()
         scannedObjectIDs.removeAll()
         newLocation = ""
         newGeneralLocation = ""
         missingMaterials.removeAll()
         selectedObjectID = nil
     }
 }

 // MARK: - View for Multi-Material Selection with Filter

 struct MultipleMaterialSelectionView: View {
     /// List of materials still available (> 0 remaining).
     var availableMaterials: [String]
     
     /// Remaining inventory, to show the user how many are left for each material.
     var remainingQuantities: [String: Int]
     
     /// Callback that returns the final quantities of each material the user chooses.
     /// The resulting dictionary is [material: enteredQuantity].
     var onCompletion: ([String: Int]) -> Void
     
     @Environment(\.dismiss) var dismiss
     
     // Step control (1: choose which materials, 2: enter quantities)
     @State private var step = 1
     
     // Set of toggled materials
     @State private var selectedMaterials: Set<String> = []
     
     // Quantities for each selected material
     @State private var quantitiesForSelected: [String: String] = [:]
     
     // --- NEW: Search text for filtering materials ---
     @State private var searchText = ""

     var filteredMaterials: [String] {
         if searchText.isEmpty {
             return availableMaterials
         } else {
             return availableMaterials.filter {
                 $0.localizedCaseInsensitiveContains(searchText)
             }
         }
     }
     
     var body: some View {
         NavigationView {
             VStack {
                 if step == 1 {
                     Text("Select Materials")
                         .font(.headline)
                         .padding()
                     
                     // Search field
                     HStack {
                         TextField("Search materials...", text: $searchText)
                             .textFieldStyle(RoundedBorderTextFieldStyle())
                             .padding(.horizontal)
                     }
                     
                     // List with toggles
                     List(filteredMaterials, id: \.self) { material in
                         HStack {
                             Text(material)
                             Spacer()
                             Text("Max: \(remainingQuantities[material, default: 0])")
                                 .font(.footnote)
                                 .foregroundColor(.gray)
                             Toggle("", isOn: Binding(
                                 get: { selectedMaterials.contains(material) },
                                 set: { newValue in
                                     if newValue {
                                         selectedMaterials.insert(material)
                                     } else {
                                         selectedMaterials.remove(material)
                                     }
                                 }
                             ))
                             .labelsHidden()
                         }
                     }

                     Button("Continue") {
                         if !selectedMaterials.isEmpty {
                             step = 2
                             // Initialize quantity text fields
                             for material in selectedMaterials {
                                 quantitiesForSelected[material] = ""
                             }
                         }
                     }
                     .padding()
                     .disabled(selectedMaterials.isEmpty)

                 } else {
                     // Step 2: capture quantities
                     Text("Enter Quantities")
                         .font(.headline)
                         .padding()

                     List(Array(selectedMaterials), id: \.self) { material in
                         HStack {
                             Text(material)
                             Spacer()
                             TextField("Quantity", text: Binding(
                                 get: { quantitiesForSelected[material] ?? "" },
                                 set: { quantitiesForSelected[material] = $0 }
                             ))
                             .keyboardType(.numberPad)
                             .frame(width: 80)
                         }
                     }

                     HStack {
                         Button("Back") {
                             step = 1
                         }
                         .padding()

                         Spacer()

                         Button("Add All") {
                             var finalDict: [String: Int] = [:]
                             for material in selectedMaterials {
                                 let textQty = quantitiesForSelected[material] ?? "0"
                                 let intQty = Int(textQty) ?? 0
                                 finalDict[material] = intQty
                             }
                             onCompletion(finalDict)
                             dismiss()
                         }
                         .padding()
                     }
                 }
             }
             .navigationBarTitle("Add Multiple Materials", displayMode: .inline)
             .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("Cancel") {
                         dismiss()
                     }
                 }
             }
         }
     }
 } */
