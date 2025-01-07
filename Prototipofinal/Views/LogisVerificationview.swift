import SwiftUI

// MARK: - Models

struct TrackingDataModel: Codable, Identifiable, Hashable {
    let id = UUID()
    let trackingNumber: String
    var items: [ItemModel]

    enum CodingKeys: String, CodingKey {
        case trackingNumber = "TrackingNumber"
        case items = "Items"
    }
}

struct ItemModel: Codable, Identifiable, Hashable {
    let id = UUID()
    let objectID: String
    let material: String
    let invoiceNumber: String
    let quantity: String
    let location: String
    let unit: String
    let date: String
    let grossWeight: Double
    let netWeight: Double

    enum CodingKeys: String, CodingKey {
        case objectID = "ObjectID"
        case material = "Material"
        case invoiceNumber = "InvoiceNumber"
        case quantity = "Quantity"
        case location = "Location"
        case unit = "Unit"
        case date = "Date"
        case grossWeight = "GrossWeight"
        case netWeight = "NetWeight"
    }
}

struct VerificationStatus: Identifiable {
    let id = UUID()
    let objectID: String
    let material: String
    var isMaterialVerified: Bool = false
    var isQuantityVerified: Bool = false
    var selectedMaterial: String = ""
    var inputQuantity: String = ""
}

// Modelo que coincide con lo que el servidor espera
struct XDockDetail: Codable {
    let TRACKING_NUMBER: String
    let OBJECT_ID: String
    let MATERIAL: String
}

// MARK: - View

struct LogisticsVerificationView: View {
    @State private var trackingData: [TrackingDataModel] = []
    @State private var selectedTrackingData: TrackingDataModel?
    @State private var tempSelectedTrackingData: TrackingDataModel?
    @State private var selectedObjectID: String?
    @State private var isLoading = false
    @State private var isSending = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isShowingExitAlert = false
    @State private var showMissingVerificationAlert = false
    @State private var missingVerifications: [String] = []
    @State private var showChangeTrackingAlert = false
    @State private var showSuccessAlert = false

    @State private var verificationStatuses: [VerificationStatus] = []

    @State private var hideBackButton = false
    @Environment(\.presentationMode) var presentationMode

    // Estado para el escaneo con cámara
    @State private var isScanning = false
    @State private var scanningMode: ScanningMode = .material
    @State private var currentIndexToScan: Int?

    enum ScanningMode {
        case material
        case quantity
    }

    init(trackingData: [TrackingDataModel] = []) {
        _trackingData = State(initialValue: trackingData)
        _tempSelectedTrackingData = State(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    if isLoading {
                        ProgressView("Loading data...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Sección Tracking Number
                                sectionBackground {
                                    Text("Select a Tracking Number")
                                        .font(.headline)
                                        .padding(.bottom, 5)

                                    Picker("Tracking Number", selection: $tempSelectedTrackingData) {
                                        Text("Select...").tag(TrackingDataModel?.none)
                                        ForEach(trackingData) { tracking in
                                            Text(tracking.trackingNumber).tag(TrackingDataModel?.some(tracking))
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onChange(of: tempSelectedTrackingData) { newValue in
                                        guard let newTracking = newValue else {
                                            selectedTrackingData = nil
                                            hideBackButton = false
                                            verificationStatuses = []
                                            selectedObjectID = nil
                                            return
                                        }

                                        // Si no se han verificado todos los ítems y ya hay un tracking seleccionado
                                        // mostramos la alerta para confirmar cambio
                                        if !allItemsVerified() && selectedTrackingData != nil {
                                            tempSelectedTrackingData = selectedTrackingData
                                            showChangeTrackingAlert = true
                                        } else {
                                            selectedTrackingData = newTracking
                                            initializeVerificationStatuses(for: newTracking)
                                            hideBackButton = true
                                            selectedObjectID = nil
                                        }
                                    }
                                }

                                if let tracking = selectedTrackingData {
                                    sectionBackground {
                                        Text("Select an Object ID")
                                            .font(.headline)
                                            .padding(.bottom, 5)

                                        Picker("Object ID", selection: $selectedObjectID) {
                                            Text("Select...").tag(String?.none)
                                            ForEach(uniqueObjectIDs(from: tracking.items), id: \.self) { objID in
                                                Text(objID).tag(String?.some(objID))
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }

                                    if let objID = selectedObjectID,
                                       let location = tracking.items.first(where: { $0.objectID == objID })?.location {
                                        sectionBackground {
                                            Text("Object ID Information")
                                                .font(.headline)
                                                .padding(.bottom, 5)
                                            Text("Location: \(location)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    if let objID = selectedObjectID {
                                        let materialsToVerifyIndices = verificationStatuses.indices.filter { verificationStatuses[$0].objectID == objID }

                                        if !materialsToVerifyIndices.isEmpty {
                                            sectionBackground {
                                                Text("Materials to Verify")
                                                    .font(.headline)
                                                    .padding(.bottom, 5)

                                                ForEach(materialsToVerifyIndices, id: \.self) { index in
                                                    let status = verificationStatuses[index]
                                                    VStack(alignment: .leading, spacing: 10) {
                                                        Text("Expected Material: \(status.material)")
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)

                                                        // Selección de material
                                                        HStack(spacing: 8) {
                                                            Picker("Select Material", selection: $verificationStatuses[index].selectedMaterial) {
                                                                Text("Select...").tag(String?.none)
                                                                ForEach(availableMaterialsGeneral(), id: \.self) { material in
                                                                    Text(material).tag(String?.some(material))
                                                                }
                                                            }
                                                            .pickerStyle(MenuPickerStyle())
                                                            .disabled(status.isMaterialVerified)
                                                            .frame(maxWidth: 150)

                                                            Button(action: {
                                                                validateMaterial(at: index)
                                                            }) {
                                                                Text("Verify Material")
                                                                    .font(.footnote)
                                                                    .foregroundColor(.white)
                                                                    .padding(6)
                                                                    .background(status.isMaterialVerified || status.selectedMaterial.isEmpty ? Color.gray : Color.blue)
                                                                    .cornerRadius(5)
                                                            }
                                                            .disabled(status.isMaterialVerified || status.selectedMaterial.isEmpty)

                                                            Button(action: {
                                                                scanningMode = .material
                                                                currentIndexToScan = index
                                                                isScanning = true
                                                            }) {
                                                                Text("Scan Material")
                                                                    .font(.footnote)
                                                                    .foregroundColor(.white)
                                                                    .padding(6)
                                                                    .background(status.isMaterialVerified ? Color.gray : Color.blue)
                                                                    .cornerRadius(5)
                                                            }
                                                            .disabled(status.isMaterialVerified)
                                                        }

                                                        if status.isMaterialVerified {
                                                            Text("Material Verified")
                                                                .font(.footnote)
                                                                .foregroundColor(.green)
                                                        }

                                                        HStack(spacing: 8) {
                                                            TextField("Enter Quantity", text: $verificationStatuses[index].inputQuantity)
                                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .keyboardType(.numberPad)
                                                                .disabled(status.isQuantityVerified)
                                                                .frame(maxWidth: 100)

                                                            Button(action: {
                                                                validateQuantity(at: index)
                                                            }) {
                                                                Text("Verify Quantity")
                                                                    .font(.footnote)
                                                                    .foregroundColor(.white)
                                                                    .padding(6)
                                                                    .background(status.isQuantityVerified || status.inputQuantity.isEmpty ? Color.gray : Color.blue)
                                                                    .cornerRadius(5)
                                                            }
                                                            .disabled(status.isQuantityVerified || status.inputQuantity.isEmpty)

                                                            Button(action: {
                                                                scanningMode = .quantity
                                                                currentIndexToScan = index
                                                                isScanning = true
                                                            }) {
                                                                Text("Scan Quantity")
                                                                    .font(.footnote)
                                                                    .foregroundColor(.white)
                                                                    .padding(6)
                                                                    .background(status.isQuantityVerified ? Color.gray : Color.blue)
                                                                    .cornerRadius(5)
                                                            }
                                                            .disabled(status.isQuantityVerified)
                                                        }

                                                        if status.isQuantityVerified {
                                                            Text("Quantity Verified")
                                                                .font(.footnote)
                                                                .foregroundColor(.green)
                                                        }

                                                        Divider()
                                                    }
                                                    .padding(.vertical, 5)
                                                }
                                            }
                                        }
                                    }
                                }

                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()

                    Button(action: {
                        if allItemsVerified() {
                            confirmInformation()
                        } else {
                            missingVerifications = getMissingVerifications()
                            showMissingVerificationAlert = true
                        }
                    }) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        } else {
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(allItemsVerified() ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .disabled(!allItemsVerified() || isSending)

                    if selectedTrackingData != nil && !allItemsVerified() {
                        Text("Please verify all materials and quantities to enable the Confirm button.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding([.leading, .trailing], 20)
                    }
                }
                .navigationTitle("Logistics Verification")
                .navigationBarBackButtonHidden(hideBackButton)
                .toolbar {
                    if hideBackButton {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                isShowingExitAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                        }
                    }
                }
                .onAppear(perform: fetchTrackingData)
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $isShowingExitAlert) {
                    Alert(
                        title: Text("Exit"),
                        message: Text("If you exit now, all entered data will be lost. Do you wish to continue?"),
                        primaryButton: .destructive(Text("Exit")) {
                            resetData()
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .alert(isPresented: $showMissingVerificationAlert) {
                    Alert(
                        title: Text("Missing Verifications"),
                        message: Text(missingVerifications.joined(separator: "\n")),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .alert(isPresented: $showChangeTrackingAlert) {
                    Alert(
                        title: Text("Confirm Change"),
                        message: Text("You have incomplete verifications. Changing the tracking number will discard all current data. Do you wish to proceed?"),
                        primaryButton: .destructive(Text("Change")) {
                            if let newTracking = tempSelectedTrackingData {
                                selectedTrackingData = newTracking
                                initializeVerificationStatuses(for: newTracking)
                                hideBackButton = true
                                selectedObjectID = nil
                            }
                        },
                        secondaryButton: .cancel() {
                            tempSelectedTrackingData = selectedTrackingData
                        }
                    )
                }
                .alert(isPresented: $showSuccessAlert) {
                    Alert(
                        title: Text("Success"),
                        message: Text("Verification data has been successfully sent."),
                        dismissButton: .default(Text("OK")) {
                            // Después de cerrar el alert de éxito, volvemos a cargar la data actualizada
                            fetchTrackingData()
                        }
                    )
                }
                .fullScreenCover(isPresented: $isScanning) {
                    ZStack(alignment: .topTrailing) {
                        CameraScannerView(scannedCode: .constant(nil)) { code in
                            validateScannedCode(code)
                            isScanning = false
                        }

                        Button(action: {
                            isScanning = false
                        }) {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .padding([.top, .trailing], 20)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Funciones

    func initializeVerificationStatuses(for tracking: TrackingDataModel) {
        verificationStatuses = tracking.items.map { item in
            VerificationStatus(objectID: item.objectID, material: item.material)
        }
    }

    func uniqueObjectIDs(from items: [ItemModel]) -> [String] {
        let uniqueIDs = Set(items.map { $0.objectID })
        return Array(uniqueIDs).sorted()
    }

    func allItemsVerified() -> Bool {
        return verificationStatuses.allSatisfy { $0.isMaterialVerified && $0.isQuantityVerified }
    }

    func getMissingVerifications() -> [String] {
        var missing: [String] = []
        for status in verificationStatuses {
            if !status.isMaterialVerified {
                missing.append("Material for Object ID: \(status.objectID), Material: \(status.material) not verified")
            }
            if !status.isQuantityVerified {
                missing.append("Quantity for Object ID: \(status.objectID), Material: \(status.material) not verified")
            }
        }
        return missing
    }

    func validateMaterial(at index: Int) {
        guard let tracking = selectedTrackingData else {
            showError(message: "No tracking data selected.")
            return
        }

        let status = verificationStatuses[index]
        if let item = tracking.items.first(where: { $0.objectID == status.objectID && $0.material == status.material }) {
            if status.selectedMaterial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == item.material.uppercased() {
                verificationStatuses[index].isMaterialVerified = true
            } else {
                showError(message: "The entered material does not match the expected material.")
                verificationStatuses[index].isMaterialVerified = false
            }
        } else {
            showError(message: "Item not found for \(status.objectID) and \(status.material).")
        }
    }

    func validateQuantity(at index: Int) {
        guard let tracking = selectedTrackingData else {
            showError(message: "No tracking data selected.")
            return
        }

        let status = verificationStatuses[index]
        if let item = tracking.items.first(where: { $0.objectID == status.objectID && $0.material == status.material }) {
            if let enteredQty = Int(status.inputQuantity), enteredQty == Int(item.quantity) {
                verificationStatuses[index].isQuantityVerified = true
            } else {
                showError(message: "The entered quantity does not match the expected quantity.")
                verificationStatuses[index].isQuantityVerified = false
            }
        } else {
            showError(message: "Item not found for \(status.objectID) and \(status.material).")
        }
    }

    func validateScannedCode(_ code: String) {
        guard let i = currentIndexToScan else { return }

        switch scanningMode {
        case .material:
            verificationStatuses[i].selectedMaterial = code
            validateMaterial(at: i)
        case .quantity:
            verificationStatuses[i].inputQuantity = code
            validateQuantity(at: i)
        }
    }

    func confirmInformation() {
        guard let tracking = selectedTrackingData else {
            showError(message: "No tracking number has been selected.")
            return
        }

        let xDockDetails = verificationStatuses.map { status -> XDockDetail in
            XDockDetail(
                TRACKING_NUMBER: tracking.trackingNumber,
                OBJECT_ID: status.objectID,
                MATERIAL: status.material
            )
        }
        
        // DEBUG: Imprimir el objeto antes de enviarlo
        print("DEBUG: XDockDetails a enviar:")
        xDockDetails.forEach { detail in
            print("TRACKING_NUMBER: \(detail.TRACKING_NUMBER), OBJECT_ID: \(detail.OBJECT_ID), MATERIAL: \(detail.MATERIAL)")
        }
        
        sendVerificationData(xDockDetails: xDockDetails)
    }

    func sendVerificationData(xDockDetails: [XDockDetail]) {
        isSending = true

        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/UpdateLog") else {
            showError(message: "Invalid API URL.")
            isSending = false
            return
        }

        var urlRequest = URLRequest(url: url)
        // Ajustar método según lo que requiera la API (POST o PUT)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .useDefaultKeys
            let jsonData = try encoder.encode(xDockDetails)
            
            // DEBUG: Imprimir el JSON que se va a enviar
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("DEBUG: JSON a enviar:")
                print(jsonString)
            }
            
            urlRequest.httpBody = jsonData
        } catch {
            showError(message: "Failed to encode verification data: \(error.localizedDescription)")
            isSending = false
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                isSending = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    showError(message: "Error sending data: \(error.localizedDescription)")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    showError(message: "Invalid server response.")
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    showError(message: "Server error: \(httpResponse.statusCode)")
                }
                return
            }

            DispatchQueue.main.async {
                resetData()
                showSuccessAlert = true
            }
        }.resume()
    }

    func resetData() {
        selectedTrackingData = nil
        tempSelectedTrackingData = nil
        verificationStatuses = []
        hideBackButton = false
        selectedObjectID = nil
    }

    func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    // Materiales disponibles en general (no filtrados por objectID)
    func availableMaterialsGeneral() -> [String] {
        guard let tracking = selectedTrackingData else { return [] }
        let allMaterials = tracking.items.map { $0.material }
        return Array(Set(allMaterials)).sorted()
    }

    func fetchTrackingData() {
        isLoading = true
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/SearchLog") else {
            showError(message: "Invalid URL.")
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    showError(message: "Error fetching data: \(error.localizedDescription)")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    showError(message: "Invalid server response.")
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    showError(message: "Server error: \(httpResponse.statusCode)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    showError(message: "No data received.")
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let fetchedTrackingData = try decoder.decode([TrackingDataModel].self, from: data)
                DispatchQueue.main.async {
                    self.trackingData = fetchedTrackingData
                    self.tempSelectedTrackingData = self.selectedTrackingData
                }
            } catch {
                DispatchQueue.main.async {
                    showError(message: "Error decoding data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    /// Función para estilizar secciones como tarjetas
    func sectionBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding()
        }
    }
}

// MARK: - Preview

struct LogisticsVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        LogisticsVerificationView(trackingData: sampleTrackingData)
    }

    static var sampleTrackingData: [TrackingDataModel] {
        return [
            TrackingDataModel(
                trackingNumber: "TRK12345",
                items: [
                    ItemModel(
                        objectID: "OBJ001",
                        material: "MAT001",
                        invoiceNumber: "INV001",
                        quantity: "10",
                        location: "LOC001",
                        unit: "KG",
                        date: "2024-11-28T12:00:00",
                        grossWeight: 100.0,
                        netWeight: 90.0
                    ),
                    ItemModel(
                        objectID: "OBJ001",
                        material: "MAT002",
                        invoiceNumber: "INV001",
                        quantity: "5",
                        location: "LOC001",
                        unit: "KG",
                        date: "2024-11-28T12:00:00",
                        grossWeight: 50.0,
                        netWeight: 45.0
                    ),
                    ItemModel(
                        objectID: "OBJ002",
                        material: "MAT003",
                        invoiceNumber: "INV002",
                        quantity: "20",
                        location: "LOC002",
                        unit: "PCS",
                        date: "2024-11-28T15:30:00",
                        grossWeight: 200.0,
                        netWeight: 190.0
                    )
                ]
            ),
            TrackingDataModel(
                trackingNumber: "TRK54321",
                items: [
                    ItemModel(
                        objectID: "OBJ003",
                        material: "MAT004",
                        invoiceNumber: "INV003",
                        quantity: "15",
                        location: "LOC003",
                        unit: "PCS",
                        date: "2024-11-29T10:00:00",
                        grossWeight: 150.0,
                        netWeight: 135.0
                    )
                ]
            )
        ]
    }
}
