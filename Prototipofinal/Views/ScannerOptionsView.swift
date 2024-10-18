import SwiftUI

struct MaterialChecklistView: View {
    var trackingData: [TrackingData] // Datos de seguimiento proporcionados
    var objectIDs: [String] // Lista de objectIDs

    // Estados para manejar materiales y ubicaciones
    @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
    @State private var locationsPerObjectID: [String: String] = [:]

    // Estado para manejar las cantidades restantes de cada material
    @State private var remainingQuantities: [String: Int] = [:]

    // Estados para controlar la presentación de sheets y alerts
    @State private var showingAddMaterialSheet = false
    @State private var selectedObjectID: String?
    @State private var newMaterial = ""
    @State private var newQuantityText = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    @State private var showingMissingQuantitiesAlert = false
    @State private var missingMaterials: [(material: String, quantity: Int)] = []

    // Estados para la asignación de ubicación
    @State private var showingAssignLocationSheet = false
    @State private var newLocation = ""

    // Estados para el escaneo
    @State private var showingMaterialScanner = false
    @State private var showingQuantityScanner = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
       

            // Mostrar lista de objectIDs
            List {
                ForEach(objectIDs, id: \.self) { objectID in
                    Section(header: Text("Object ID: \(objectID)").font(.headline)) {

                        // Mostrar ubicación asignada si existe
                        if let location = locationsPerObjectID[objectID] {
                            HStack {
                                Text("Ubicación Asignada:")
                                Spacer()
                                Text(location)
                                    .fontWeight(.bold)
                            }
                        }

                        // Botón para asignar ubicación
                        Button(action: {
                            selectedObjectID = objectID
                            showingAssignLocationSheet = true
                        }) {
                            Text(locationsPerObjectID[objectID] != nil ? "Cambiar Ubicación" : "Asignar Ubicación")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 5)

                        // Mostrar materiales agregados a este objectID
                        if let materials = materialsPerObjectID[objectID] {
                            ForEach(materials) { entry in
                                HStack {
                                    Text("Material: \(entry.material)")
                                    Spacer()
                                    Text("Cantidad: \(entry.quantity)")
                                }
                            }
                        }

                        // Botón para agregar material a este objectID
                        Button(action: {
                            selectedObjectID = objectID
                            showingAddMaterialSheet = true
                        }) {
                            Text("Agregar Material")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .padding(.bottom)

            // Mostrar cantidades restantes de cada material en una lista pequeña
            VStack(alignment: .leading) {
                Text("Cantidades Restantes:")
                    .font(.headline)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(remainingQuantities.keys.sorted(), id: \.self) { material in
                            VStack {
                                Text(material)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Restante: \(remainingQuantities[material]!)")
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

            // Botón de Enviar
            Button(action: {
                checkForMissingQuantitiesAndSendData()
            }) {
                Text("Enviar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Cheklist PakingList")
        .onAppear {
            initializeRemainingQuantities()
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
                Text("Agregar Material")
                    .font(.headline)
                    .padding()

                // Material Input with Camera Icon
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

                // Quantity Input with Camera Icon
                HStack {
                    TextField("Cantidad", text: $newQuantityText)
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
                    Button("Cancelar") {
                        showingAddMaterialSheet = false
                        newMaterial = ""
                        newQuantityText = ""
                    }
                    .padding()
                    Spacer()
                    Button("Agregar") {
                        addMaterial()
                        showingAddMaterialSheet = false
                    }
                    .padding()
                }
            }
            .padding()
            // Present scanner sheets for Material and Quantity
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
        // Error Alert
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("Aceptar")))
        }
        // Success Alert
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text("Éxito"), message: Text("Datos enviados correctamente."), dismissButton: .default(Text("Aceptar")))
        }
        // Missing Quantities Alert
        .alert(isPresented: $showingMissingQuantitiesAlert) {
            Alert(
                title: Text("Cantidades Faltantes"),
                message: Text(missingMaterialsMessage()),
                primaryButton: .destructive(Text("Continuar")) {
                    sendData()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
    // Función para inicializar las cantidades restantes
    func initializeRemainingQuantities() {
        let grouped = Dictionary(grouping: trackingData, by: { $0.material })
        for (material, entries) in grouped {
            // Convertir deliveryQty de String a Int de forma segura
            let totalQuantity = entries.reduce(0) { (result, data) -> Int in
                let qty = Int(data.deliveryQty) ?? 0
                return result + qty
            }
            remainingQuantities[material] = totalQuantity
        }
    }

    // Función para agregar material
    func addMaterial() {
        guard let objectID = selectedObjectID else { return }
        let material = newMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityStr = newQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)

        if material.isEmpty || quantityStr.isEmpty {
            showError(message: "Por favor, completa todos los campos.")
            return
        }

        if let quantity = Int(quantityStr), quantity > 0 {
            if let remaining = remainingQuantities[material], remaining >= quantity {
                // Restar la cantidad del material
                remainingQuantities[material] = remaining - quantity

                // Agregar el material al objectID
                let location = locationsPerObjectID[objectID] ?? ""
                let entry = MaterialEntry(id: UUID(), material: material, quantity: quantity, location: location)
                materialsPerObjectID[objectID, default: []].append(entry)
            } else {
                showError(message: "Cantidad insuficiente para el material \(material).")
            }
        } else {
            showError(message: "Cantidad inválida. Por favor, ingresa un número válido.")
        }

        // Resetear los campos
        newMaterial = ""
        newQuantityText = ""
    }

    // Función para asignar ubicación
    func assignLocation() {
        guard let objectID = selectedObjectID else { return }
        let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if location.isEmpty {
            showError(message: "Por favor, ingresa una ubicación.")
            return
        }

        // Asignar la ubicación al objectID
        locationsPerObjectID[objectID] = location

        // Actualizar las ubicaciones en los materiales asignados a este objectID
        if var materials = materialsPerObjectID[objectID] {
            for index in materials.indices {
                materials[index].location = location
            }
            materialsPerObjectID[objectID] = materials
        }

        // Resetear el campo
        newLocation = ""
    }

    // Función para mostrar un error
    func showError(message: String) {
        errorMessage = message
        showingErrorAlert = true
    }

    // Función para verificar cantidades faltantes y enviar datos
    func checkForMissingQuantitiesAndSendData() {
        // Verificar si hay cantidades faltantes
        var missingMaterialsDict: [String: Int] = [:]
        for (material, remaining) in remainingQuantities {
            if remaining > 0 {
                missingMaterialsDict[material] = remaining
            }
        }

        if !missingMaterialsDict.isEmpty {
            // Hay materiales con cantidades faltantes
            missingMaterials = missingMaterialsDict.map { ($0.key, $0.value) }
            showingMissingQuantitiesAlert = true
        } else {
            // No hay cantidades faltantes, enviar datos
            sendData()
        }
    }

    // Función para generar el mensaje de materiales faltantes
    func missingMaterialsMessage() -> String {
        var message = "Faltan las siguientes cantidades:\n"
        for (material, quantity) in missingMaterials {
            message += "- \(material): \(quantity)\n"
        }
        message += "\n¿Deseas continuar?"
        return message
    }

    // Función para enviar los datos
    func sendData() {
        // Crear un diccionario para agrupar los materiales
        var groupedMaterials: [MaterialKey: MaterialData] = [:]

        // Recorrer cada objectID
        for objectID in objectIDs {
            guard let location = locationsPerObjectID[objectID] else {
                showError(message: "Falta la ubicación para el Object ID \(objectID).")
                return
            }

            guard let materials = materialsPerObjectID[objectID], !materials.isEmpty else {
                showError(message: "No se han agregado materiales para el Object ID \(objectID).")
                return
            }

            // Recorrer cada material asignado a este objectID
            for entry in materials {
                let key = MaterialKey(objectID: objectID, material: entry.material, location: location)

                // Sumar las cantidades de materiales duplicados
                if let existingData = groupedMaterials[key] {
                    var updatedData = existingData
                    updatedData.QUANTITY += entry.quantity
                    groupedMaterials[key] = updatedData
                } else {
                    // Buscar en trackingData la entrada correspondiente al material
                    if let trackingEntry = trackingData.first(where: { $0.material == entry.material }) {
                        // Crear el objeto MaterialData
                        let materialData = MaterialData(
                            OBJECT_ID: objectID,
                            TRACKING_NUMBER: trackingEntry.externalDeliveryID,
                            INVOICE_NUMBER: trackingEntry.externalDeliveryID,
                            MATERIAL: trackingEntry.material,
                            QUANTITY: entry.quantity,
                            LOCATION: location,
                            DELIVERY_TYPE:nil,
                            BILL: "Y"
                        )
                        groupedMaterials[key] = materialData
                    } else {
                        showError(message: "No se encontró información de tracking para el material \(entry.material).")
                        return
                    }
                }
            }
        }

        // Convertir el diccionario a un arreglo
        let jsonDataArray = Array(groupedMaterials.values)

        // Enviar los JSONs a la API
        sendJSONData(jsonDataArray)
    }

    // Función para enviar los JSONs a la API
    func sendJSONData(_ data: [MaterialData]) {
        // Convertir el arreglo de MaterialData a JSON
        guard let jsonData = try? JSONEncoder().encode(data) else {
            showError(message: "Error al codificar los datos a JSON.")
            return
        }

        // Crear la solicitud a la API
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/update"
        guard let url = URL(string: urlString) else {
            showError(message: "URL inválida.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Realizar la solicitud
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showError(message: "Error al enviar los datos: \(error.localizedDescription)")
                }
                return
            }

            // Verificar la respuesta
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.showSuccess()
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(message: "Error en la respuesta del servidor.")
                }
            }
        }
        task.resume()
    }

    // Función para mostrar éxito
    func showSuccess() {
        showingSuccessAlert = true
        // Aquí puedes resetear los datos si lo deseas
        materialsPerObjectID.removeAll()
        locationsPerObjectID.removeAll()
        remainingQuantities.removeAll()
    }
}

// Estructura para representar una entrada de material
struct MaterialEntry: Identifiable {
    let id: UUID
    let material: String
    var quantity: Int
    var location: String
}

// Estructura para la clave de agrupación de materiales
struct MaterialKey: Hashable {
    let objectID: String
    let material: String
    let location: String
}

// Estructura para representar los datos a enviar
struct MaterialData: Codable {
    let OBJECT_ID: String
    let TRACKING_NUMBER: String?
    let INVOICE_NUMBER: String?
    let MATERIAL: String
    var QUANTITY: Int
    let LOCATION: String
    let DELIVERY_TYPE: String?
    let BILL: String
}

// Estructura para representar los datos de seguimiento
