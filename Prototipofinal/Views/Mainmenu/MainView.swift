import SwiftUI

// Estructura de ejemplo para TrackingData (asegúrate de que externalDeliveryID sea var)


// Vista para ingresar el nuevo tracking en búsquedas múltiples
struct NewTrackingInputView: View {
    @Binding var newTracking: String
    var assignAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Text("Ingrese el nuevo número de tracking para asignar a todos los materiales.")
                    .multilineTextAlignment(.center)
                    .padding()
                TextField("Nuevo Tracking", text: $newTracking)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Nuevo Tracking")
            .navigationBarItems(
                leading: Button("Cancelar", action: cancelAction),
                trailing: Button("Asignar", action: assignAction)
            )
        }
    }
}

// ContentView completa
struct ContentView: View {
    // Objeto global para "Inbond" / "Domestic"
    @EnvironmentObject var shipmentState: ShipmentState

    // Campo de entrada (se usa para uno o más números de referencia)
    @State private var referenceNumber = ""
    @State private var selectedShipmentType = "More Information"
    @State private var shouldNavigateToPrint = false
    @State private var shouldNavigateToChecklist = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isScanning = false
    @State private var apiResponse: [TrackingData]?
    @State private var storedTrackingData: [TrackingData] = []
    @State private var uniqueObjectIDCount: Int = 0
    @State private var uniqueObjectIDs: [String] = []
    @State private var useCustomLabels = true
    @State private var customLabels = 1
    @State private var objectIDsFromPrint: [String] = []
    @State private var shouldNavigateToExportView = false
    @State private var navigateToExportView = false
    @State private var shouldNavigateToManualInsertion = false
    @State private var showManualInsertionAlert = false
    @State private var navigateToLogisticsVerificationView = false

    // NUEVO: Variables para la asignación del nuevo tracking en búsquedas múltiples
    @State private var newTrackingNumber = ""
    @State private var showNewTrackingAlert = false

    // NUEVO: Controla la visibilidad del menú lateral
    @State private var showSideMenu = false

    let shipmentTypes = ["More Information", "Printing", "Verification", "Logis", "Export"]
    let apiService = APIService()

    var body: some View {
        NavigationView {
            ZStack {
                // ===== Contenido principal =====
                ZStack {
                    VStack(spacing: 16) {
                        AppHeader()

                        ReferenceInputView(referenceNumber: $referenceNumber, isScanning: $isScanning)
                            .onSubmit {
                                initiateNewSearch()
                            }
                            .onChange(of: referenceNumber) { newValue in
                                referenceNumber = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            }

                        // Picker principal para "More Information", "Printing", etc.
                        Picker("Option Type", selection: $selectedShipmentType) {
                            ForEach(shipmentTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 8)

                        // Vista adicional basada en la selección
                        if selectedShipmentType == "More Information" {
                            if isLoading {
                                ProgressView("Loading data...")
                            } else if let trackingData = apiResponse, !trackingData.isEmpty {
                                // Picker Global para "Inbond" y "Domestic"
                                Picker(selection: $shipmentState.selectedInboundType, label: Text("Options")) {
                                    Text("Inbond").tag("Inbond" as String?)
                                    Text("Domestic").tag("Domestic" as String?)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal, 8)

                                // Vista de materiales
                                MaterialListView(trackingData: storedTrackingData)
                                    .frame(maxHeight: 300)
                                    .padding(.horizontal, 8)
                            } else {
                                Text("No data found.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                            }
                        } else if selectedShipmentType == "Printing" {
                            PrintingView(useCustomLabels: $useCustomLabels, customLabels: $customLabels)
                        } else if selectedShipmentType == "Verification" {
                            EmptyView()
                        } else if selectedShipmentType == "Logis" {
                            EmptyView()
                        } else if selectedShipmentType == "Export" {
                            EmptyView()
                        } else {
                            EmptyView()
                        }

                        Spacer()

                        if isLoading && selectedShipmentType != "More Information" {
                            ProgressView("Loading...")
                        }

                        // Botón "Print" solo si la opción "Printing" está seleccionada
                        if selectedShipmentType == "Printing" {
                            Button(action: {
                                handlePrintButton()
                            }) {
                                Text("Print \(useCustomLabels ? customLabels : uniqueObjectIDCount) labels")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isLoading ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(
                                isLoading ||
                                referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                (apiResponse == nil || apiResponse!.isEmpty)
                            )
                            .padding(.horizontal, 8)
                        }

                        // Texto de redirección para "Export" y "Logis"
                        if selectedShipmentType == "Export" {
                            Text("Redirecting to ExportView...")
                                .onAppear { navigateToExportView = true }
                        }
                        if selectedShipmentType == "Logis" {
                            Text("Redirecting to LogisView...")
                                .onAppear { navigateToLogisticsVerificationView = true }
                        }

                        // Navegaciones ocultas
                        NavigationLink(
                            destination: ManualInsertionView(),
                            isActive: $shouldNavigateToManualInsertion
                        ) { EmptyView() }

                        NavigationLink(
                            destination: LogisticsVerificationView(),
                            isActive: $navigateToLogisticsVerificationView
                        ) { EmptyView() }
                        NavigationLink(
                            destination: ExportView(),
                            isActive: $navigateToExportView
                        ) { EmptyView() }

                        NavigationLink(
                            destination: PrintView(
                                referenceNumber: storedTrackingData.first?.externalDeliveryID ?? referenceNumber,
                                trackingData: storedTrackingData,
                                customLabels: customLabels,
                                useCustomLabels: useCustomLabels,
                                finalObjectIDs: $objectIDsFromPrint
                            ),
                            isActive: $shouldNavigateToPrint
                        ) { EmptyView() }

                        NavigationLink(
                            destination: MaterialChecklistView(
                                trackingData: storedTrackingData,
                                objectIDs: objectIDsFromPrint
                            ),
                            isActive: $shouldNavigateToChecklist
                        ) { EmptyView() }
                    }
                    .navigationTitle("Material Import")
                    // Alertas de error e inserción manual
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    .alert(isPresented: $showManualInsertionAlert) {
                        Alert(
                            title: Text("No data found"),
                            message: Text("Would you like to enter data manually?"),
                            primaryButton: .default(Text("Yes"), action: { shouldNavigateToManualInsertion = true }),
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    }
                }
                // Cámara para escanear
                .sheet(isPresented: $isScanning) {
                    CameraScannerWrapperView(scannedCode: .constant(nil)) { code in
                        referenceNumber = code.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: " ", with: "")
                        isScanning = false
                        initiateNewSearch()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                // Presenta el sheet para el nuevo tracking en búsquedas múltiples
                .sheet(isPresented: $showNewTrackingAlert) {
                    NewTrackingInputView(newTracking: $newTrackingNumber,
                                         assignAction: {
                                            assignNewTrackingNumber(newTrackingNumber)
                                            showNewTrackingAlert = false
                                         },
                                         cancelAction: {
                                            showNewTrackingAlert = false
                                         })
                }
                // Ocultar teclado al tocar fuera
                .onTapGesture {
                    hideKeyboard()
                }
                // Observa cambios en el Picker principal
                .onChange(of: selectedShipmentType) { newValue in
                    if newValue == "Verification" {
                        if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            alertMessage = "You need a reference number to continue."
                            showAlert = true
                            selectedShipmentType = "More Information"
                        } else if apiResponse == nil || apiResponse!.isEmpty {
                            alertMessage = "No data found for the provided reference number."
                            showAlert = true
                            selectedShipmentType = "More Information"
                        } else {
                            storedTrackingData = apiResponse ?? []
                            shouldNavigateToChecklist = true
                        }
                    } else if newValue == "Export" {
                        if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            alertMessage = "You need a reference number to continue."
                            showAlert = true
                            selectedShipmentType = "More Information"
                        } else if apiResponse == nil || apiResponse!.isEmpty {
                            alertMessage = "No data found for the provided reference number."
                            showAlert = true
                            selectedShipmentType = "More Information"
                        } else {
                            shouldNavigateToExportView = true
                        }
                    }
                }

                // ===== Menú lateral (Side Menu) =====
                if showSideMenu {
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Menú")
                                .font(.headline)
                                .padding(.top, 50)

                            NavigationLink(destination: NewFormView()) {
                                Text("Material Unknown")
                            }
                            .padding(.vertical, 8)
                            NavigationLink(destination: InsertToolingView()) {
                                Text("Insert Tooling")
                            }
                            .padding(.vertical, 8)
                            NavigationLink(destination: DeliverySearchView()) {
                                Text("Search")
                            }
                            .padding(.vertical, 8)
                            Spacer()
                        }
                        .frame(width: 250)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .shadow(radius: 5)

                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
            // Botón estilo hamburguesa
            .navigationBarItems(
                leading: Button(action: {
                    withAnimation {
                        showSideMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                }
            )
        }
    }

    // MARK: - Funciones de lógica

    // Función para manejar el botón Print
    func handlePrintButton() {
        let trimmedReference = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedReference.isEmpty {
            alertMessage = "You need a reference number to continue."
            showAlert = true
            return
        }
        if apiResponse != nil && !(apiResponse?.isEmpty ?? true) {
            shouldNavigateToPrint = true
        } else {
            initiateNewSearch()
        }
    }

    // Función para detectar múltiples referencias
    func initiateNewSearch() {
        referenceNumber = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiResponse = nil
        self.storedTrackingData = []
        self.uniqueObjectIDs = []
        self.uniqueObjectIDCount = 0
        self.objectIDsFromPrint = []
        self.showAlert = false
        self.alertMessage = ""
        self.showManualInsertionAlert = false
        
        // Si se detecta una coma, se trata de múltiples referencias
        if referenceNumber.contains(",") {
            let references = referenceNumber.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let dispatchGroup = DispatchGroup()
            isLoading = true
            
            for ref in references {
                dispatchGroup.enter()
                fetchAPIResponse(for: ref) {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                isLoading = false
                if storedTrackingData.isEmpty {
                    alertMessage = "No se encontraron datos para las referencias ingresadas."
                    showAlert = true
                } else {
                    // Presenta el sheet para solicitar el nuevo tracking
                    showNewTrackingAlert = true
                }
            }
        } else {
            // Búsqueda individual con la referencia ingresada
            fetchAPIResponse()
        }
    }

    // Función para la búsqueda individual
    func fetchAPIResponse() {
        let trimmedReference = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        referenceNumber = trimmedReference

        guard !trimmedReference.isEmpty else {
            self.alertMessage = "Please complete the reference number before proceeding."
            self.showAlert = true
            print("Debug: Reference number is empty.")
            return
        }

        isLoading = true
        print("Debug: Starting search for reference: \(trimmedReference)")

        apiService.fetchData(referenceNumber: trimmedReference) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let trackingData):
                    print("Debug: Successful call. Data obtained: \(trackingData.count)")
                    if trackingData.isEmpty {
                        self.showManualInsertionAlert = true
                        print("Debug: No data found. Asking user if they want to enter data manually.")
                    } else {
                        self.apiResponse = trackingData
                        self.storedTrackingData = trackingData
                        let uniqueIDsSet = Set(trackingData.map { $0.externalDeliveryID })
                        self.uniqueObjectIDs = Array(uniqueIDsSet)
                        self.uniqueObjectIDCount = self.uniqueObjectIDs.count
                        print("Debug: Found \(self.uniqueObjectIDCount) unique IDs.")
                    }
                case .failure(let error):
                    self.alertMessage = "An error occurred: \(error.localizedDescription)"
                    self.showAlert = true
                    print("Debug: An error occurred: \(error.localizedDescription).")
                }
            }
        }
    }

    // Función para búsquedas múltiples (cada referencia individual)
    func fetchAPIResponse(for reference: String, completion: @escaping () -> Void) {
        let trimmedReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReference.isEmpty else {
            self.alertMessage = "Please complete the reference number before proceeding."
            self.showAlert = true
            completion()
            return
        }
        print("Debug: Starting search for reference: \(trimmedReference)")
        apiService.fetchData(referenceNumber: trimmedReference) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let trackingData):
                    print("Debug: Successful call for \(trimmedReference). Data obtained: \(trackingData.count)")
                    if !trackingData.isEmpty {
                        self.apiResponse = (self.apiResponse ?? []) + trackingData
                        self.storedTrackingData += trackingData
                        let uniqueIDsSet = Set(self.storedTrackingData.map { $0.externalDeliveryID })
                        self.uniqueObjectIDs = Array(uniqueIDsSet)
                        self.uniqueObjectIDCount = self.uniqueObjectIDs.count
                        print("Debug: Total unique IDs consolidated: \(self.uniqueObjectIDCount)")
                    }
                case .failure(let error):
                    self.alertMessage = "An error occurred: \(error.localizedDescription)"
                    self.showAlert = true
                    print("Debug: An error occurred: \(error.localizedDescription)")
                }
                completion()
            }
        }
    }

    // Función para asignar el nuevo tracking a todos los materiales consolidados
    func assignNewTrackingNumber(_ newTracking: String) {
        let trimmedNewTracking = newTracking.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewTracking.isEmpty else {
            alertMessage = "El nuevo número de tracking no puede estar vacío."
            showAlert = true
            return
        }
        storedTrackingData = storedTrackingData.map { data in
            var modifiedData = data
            modifiedData.externalDeliveryID = trimmedNewTracking
            return modifiedData
        }
        apiResponse = storedTrackingData
        print("Nuevo tracking asignado: \(trimmedNewTracking) a todos los materiales.")
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
