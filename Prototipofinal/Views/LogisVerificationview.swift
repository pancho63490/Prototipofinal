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
    let country : String
    let vendor: String
    let type: String
    let ID : Int

    enum CodingKeys: String, CodingKey {
        case ID = "id"
        case objectID = "ObjectID"
        case material = "Material"
        case invoiceNumber = "InvoiceNumber"
        case quantity = "Quantity"
        case location = "Location"
        case unit = "Unit"
        case date = "Date"
        case grossWeight = "GrossWeight"
        case netWeight = "NetWeight"
        case country = "country"
        case vendor = "Vendor"
        case type = "type"
    }
}

struct VerificationStatus: Identifiable {
    let id = UUID()
    let objectID: String
    let material: String
    var isVerified: Bool = false
}

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
    @State private var verificationStatuses: [VerificationStatus] = []
    
    @State private var isLoading = false
    @State private var isSending = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isShowingExitAlert = false
    @State private var showChangeTrackingAlert = false
    @State private var showSuccessAlert = false
    @State private var showNotAllVerifiedAlert = false
    
    @State private var hideBackButton = false
    @Environment(\.presentationMode) var presentationMode
    
    init(trackingData: [TrackingDataModel] = []) {
        _trackingData = State(initialValue: trackingData)
        _tempSelectedTrackingData = State(initialValue: nil)
    }
    
    var body: some View {
        Banner()
        NavigationView {
            
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Indicador de carga
                    if isLoading {
                        ProgressView("Loading data...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        // Contenido principal
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                
                                // MARK: - Selector de Tracking Number
                                sectionBackground {
                                    Text("Select a Tracking Number")
                                        .font(.headline)
                                        .padding(.bottom, 5)
                                    
                                    Picker("Tracking Number", selection: $tempSelectedTrackingData) {
                                        Text("Select...").tag(TrackingDataModel?.none)
                                        ForEach(trackingData) { tracking in
                                            Text(tracking.trackingNumber)
                                                .tag(TrackingDataModel?.some(tracking))
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onChange(of: tempSelectedTrackingData) { newValue in
                                        guard let newTracking = newValue else {
                                            // Si el usuario deselecciona
                                            selectedTrackingData = nil
                                            hideBackButton = false
                                            verificationStatuses = []
                                            return
                                        }
                                        
                                        // Si hay un tracking previo y no está todo verificado, pedimos confirmación
                                        if let current = selectedTrackingData,
                                           !allItemsVerified() {
                                            // Comprobamos si cambió a un tracking distinto
                                            if current.trackingNumber != newTracking.trackingNumber {
                                                showChangeTrackingAlert = true
                                            }
                                        } else {
                                            // No hay conflicto
                                            selectedTrackingData = newTracking
                                            initializeVerificationStatuses(for: newTracking)
                                            hideBackButton = true
                                        }
                                    }
                                }
                                
                                // MARK: - Contador de Pallets (Unique ObjectIDs)
                                if let tracking = selectedTrackingData {
                                    let uniqueObjectIDsCount = Set(tracking.items.map { $0.objectID }).count
                                    Text("Total Unique pallets: \(uniqueObjectIDsCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                }
                                
                                // MARK: - Tabla de Items usando Grid (iOS 16+)
                                if let tracking = selectedTrackingData {
                                    sectionBackground {
                                        Text("Items to Verify")
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        
                                        // Scroll horizontal para no desbordar si las columnas son muy anchas
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            // Ajustamos espaciados y alineaciones a gusto
                                            Grid(alignment: .topLeading,
                                                 horizontalSpacing: 10,
                                                 verticalSpacing: 10) {
                                                
                                                // 6 columnas: 5 datos + 1 check
                                                GridRow {
                                                    Text("ObjectID").fontWeight(.bold)
                                                    Text("Material").fontWeight(.bold)
                                                    Text("Quantity").fontWeight(.bold)
                                                    Text("Location").fontWeight(.bold)
                                                    Text("Country").fontWeight(.bold)
                                                    Text("Vendor").fontWeight(.bold)
                                                    Text("Type").fontWeight(.bold)
                                                    Text("Check").fontWeight(.bold)
                                                    
                                                }
                                                Divider()
                                                    .gridCellColumns(6)
                                                
                                                // Filas de datos
                                                ForEach(tracking.items.indices, id: \.self) { index in
                                                    let item = tracking.items[index]
                                                    let status = verificationStatuses[index]
                                                    
                                                    GridRow {
                                                        Text(item.objectID)
                                                        Text(item.material)
                                                        Text(item.quantity)
                                                        Text(item.location)
                                                        Text(item.country)
                                                        Text(item.vendor)
                                                        Text(item.type)
                                                        
                                                        Button(action: {
                                                            verificationStatuses[index].isVerified.toggle()
                                                        }) {
                                                            Image(systemName: status.isVerified
                                                                  ? "checkmark.square.fill"
                                                                  : "square")
                                                                .resizable()
                                                                .frame(width: 24, height: 24)
                                                                .foregroundColor(
                                                                    status.isVerified ? .green : .blue
                                                                )
                                                        }
                                                    }
                                                    Divider()
                                                        .gridCellColumns(6)
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
                    
                    // MARK: - Botón Confirm
                    Button(action: {
                        if !allItemsVerified() {
                            showNotAllVerifiedAlert = true
                            return
                        }
                        confirmInformation()
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
                }
                .navigationTitle("Logistics Verification")
                .navigationBarBackButtonHidden(hideBackButton)
                .toolbar {
                    // MARK: - Botón Back personalizado
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
                // MARK: - onAppear
                .onAppear(perform: fetchTrackingData)
                
                // MARK: - Alertas
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
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
                .alert(isPresented: $showChangeTrackingAlert) {
                    Alert(
                        title: Text("Change Tracking?"),
                        message: Text("You have incomplete verifications. Changing the tracking number will discard current data."),
                        primaryButton: .default(Text("Yes, Change")) {
                            if let newTracking = tempSelectedTrackingData {
                                selectedTrackingData = newTracking
                                initializeVerificationStatuses(for: newTracking)
                                hideBackButton = true
                            }
                        },
                        secondaryButton: .cancel {
                            // Revertimos el picker al valor anterior
                            tempSelectedTrackingData = selectedTrackingData
                        }
                    )
                }
                .alert(isPresented: $showSuccessAlert) {
                    Alert(
                        title: Text("Success"),
                        message: Text("Verification data has been successfully sent."),
                        dismissButton: .default(Text("OK")) {
                            // Puedes volver a hacer fetch o resetear
                            fetchTrackingData()
                        }
                    )
                }
                .alert(isPresented: $showNotAllVerifiedAlert) {
                    Alert(
                        title: Text("Incomplete Verification"),
                        message: Text("All items must be checked before confirming."),
                        dismissButton: .default(Text("OK"))
                    )
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
    
    func allItemsVerified() -> Bool {
        verificationStatuses.allSatisfy { $0.isVerified }
    }
    
    func confirmInformation() {
        guard let tracking = selectedTrackingData else {
            showError(message: "No tracking number selected.")
            return
        }
        
        let xDockDetails = verificationStatuses.map { status -> XDockDetail in
            XDockDetail(
                TRACKING_NUMBER: tracking.trackingNumber,
                OBJECT_ID: status.objectID,
                MATERIAL: status.material
            )
        }
        
        print("DEBUG: XDockDetails to send:")
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
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .useDefaultKeys
            let jsonData = try encoder.encode(xDockDetails)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("DEBUG: JSON to send:\n\(jsonString)")
            }
            
            urlRequest.httpBody = jsonData
        } catch {
            showError(message: "Failed to encode verification data: \(error.localizedDescription)")
            isSending = false
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async { self.isSending = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showError(message: "Error sending data: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.showError(message: "Invalid server response.")
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.showError(message: "Server error: \(httpResponse.statusCode)")
                }
                return
            }
            
            // Todo bien
            DispatchQueue.main.async {
                self.resetData()
                self.showSuccessAlert = true
            }
        }.resume()
    }
    
    func resetData() {
        selectedTrackingData = nil
        tempSelectedTrackingData = nil
        verificationStatuses = []
        hideBackButton = false
    }
    
    func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
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
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showError(message: "Error fetching data: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.showError(message: "Invalid server response.")
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.showError(message: "Server error: \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showError(message: "No data received.")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                var fetchedTrackingData = try decoder.decode([TrackingDataModel].self, from: data)
                
                // Ordenamos cada tracking por ID
                fetchedTrackingData = fetchedTrackingData.map { tracking in
                    var mutableTracking = tracking
                    mutableTracking.items = tracking.items.sorted { $0.ID < $1.ID }
                    return mutableTracking
                }
                
                // Ordenamos los trackingData por trackingNumber
                fetchedTrackingData = fetchedTrackingData.sorted { $0.trackingNumber < $1.trackingNumber }
                print(fetchedTrackingData)
                DispatchQueue.main.async {
                    self.trackingData = fetchedTrackingData
                    self.tempSelectedTrackingData = self.selectedTrackingData
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError(message: "Error decoding data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    /// "Card" style para secciones
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
