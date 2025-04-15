import SwiftUI
struct GroupingInputView: View {
    @Binding var grouping: String
    var confirmAction: () -> Void
    var cancelAction: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo neutro y sutil con color gris claro
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Banner()
                    // Título centralizado con tipografía moderna
                    Text("Ingrese el número de Grouping / Tracking para asignar a todos los materiales.")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Color(.darkGray))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    
                    // Contenedor neutro para el TextField
                    VStack {
                        TextField("Número de Grouping", text: $grouping)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal, 25)
                    
                    Spacer()
                }
            }
            .navigationTitle("Grouping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botón de cancelar a la izquierda
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: cancelAction) {
                        Text("Cancelar")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                    }
                }
                // Botón de confirmar a la derecha
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: confirmAction) {
                        Text("OK")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                    }
                }
            }
        }
    }
}

// Nuevo banner minimalista y delgado
struct Banner: View {
    var body: some View {
        Image("banner")
            .resizable()
            .scaledToFill()
            .frame(height: 20)  // Ajusta la altura para hacerlo más o menos delgado
            .clipped()
    }
}

// ContentView completa con estilo minimalista
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

    // NUEVO: Variables para la asignación de grouping/tracking consolidado
    @State private var newGroupingValue = ""       // <–– Aquí guardaremos el valor unificado
    @State private var showGroupingSheet = false   // <–– Controla si se muestra la vista

    // NUEVO: Controla la visibilidad del menú lateral
    @State private var showSideMenu = false

    let shipmentTypes = ["More Information", "Printing", "Verification", "Logis", "Export"]
    let apiService = APIService()

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Contenido Principal
                VStack(spacing: 8) {
                    // Banner y encabezado
                    Banner()
                    AppHeader()
                    
                    // Campo de texto con gestión de espacios y opciones de escaneo
                    ReferenceInputView(referenceNumber: $referenceNumber, isScanning: $isScanning)
                        .padding(.horizontal, 8)
                        .onSubmit { initiateNewSearch() }
                        .onChange(of: referenceNumber) { newValue in
                            referenceNumber = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    
                    // Picker principal para seleccionar el tipo de envío
                    Picker("Option Type", selection: $selectedShipmentType) {
                        ForEach(shipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 8)
                    
                    // Vista condicional según la opción seleccionada
                    Group {
                        switch selectedShipmentType {
                        case "More Information":
                            moreInformationView
                        case "Printing":
                            PrintingView(useCustomLabels: $useCustomLabels, customLabels: $customLabels)
                        case "Verification", "Logis", "Export":
                            EmptyView()
                        default:
                            EmptyView()
                        }
                    }
                    
                    Spacer()
                    
                    // Indicador de carga para opciones distintas de "More Information"
                    if isLoading && selectedShipmentType != "More Information" {
                        ProgressView("Loading...")
                    }
                    
                    // Botón de impresión solo para "Printing"
                    if selectedShipmentType == "Printing" {
                        Button(action: { handlePrintButton() }) {
                            Text("Print \(useCustomLabels ? customLabels : uniqueObjectIDCount) labels")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isLoading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isLoading ||
                                  referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  (apiResponse == nil || apiResponse!.isEmpty))
                        .padding(.horizontal, 8)
                    }
                    
                    // Redirecciones para "Export" y "Logis"
                    if selectedShipmentType == "Export" {
                        Text("Redirecting to ExportView...")
                            .onAppear { navigateToExportView = true }
                    }
                    if selectedShipmentType == "Logis" {
                        Text("Redirecting to LogisView...")
                            .onAppear { navigateToLogisticsVerificationView = true }
                    }
                }
                // Fin del Contenido Principal
                
                // MARK: - Menú Lateral (Side Menu)
                if showSideMenu {
                    HStack {
                        sideMenuView
                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
            // MARK: - Modificadores Globales
            .navigationTitle("Robert Bosch JuP2")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                withAnimation { showSideMenu.toggle() }
            }) {
                Image(systemName: "line.horizontal.3")
            })
            // Ocultar el teclado al tocar fuera
            .onTapGesture { hideKeyboard() }
            
            // MARK: - Alertas
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showManualInsertionAlert) {
                Alert(
                    title: Text("No data found"),
                    message: Text("Would you like to enter data manually?"),
                    primaryButton: .default(Text("Yes"), action: { shouldNavigateToManualInsertion = true }),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            
            // MARK: - Navegaciones ocultas
            .background(
                NavigationLink(destination: ManualInsertionView(), isActive: $shouldNavigateToManualInsertion) {
                    EmptyView()
                }
                .hidden()
            )
            .background(
                NavigationLink(destination: LogisticsVerificationView(), isActive: $navigateToLogisticsVerificationView) {
                    EmptyView()
                }
                .hidden()
            )
            .background(
                NavigationLink(destination: ExportView(), isActive: $navigateToExportView) {
                    EmptyView()
                }
                .hidden()
            )
            .background(
                NavigationLink(
                    destination: PrintView(
                        referenceNumber: storedTrackingData.first?.grouping ?? referenceNumber,
                        trackingData: storedTrackingData,
                        customLabels: customLabels,
                        useCustomLabels: useCustomLabels,
                        finalObjectIDs: $objectIDsFromPrint
                    ),
                    isActive: $shouldNavigateToPrint
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .background(
                NavigationLink(
                    destination: MaterialChecklistView(trackingData: storedTrackingData, objectIDs: objectIDsFromPrint),
                    isActive: $shouldNavigateToChecklist
                ) {
                    EmptyView()
                }
                .hidden()
            )
            
            // MARK: - Hojas (Sheets)
            // CameraScanner
            .sheet(isPresented: $isScanning) {
                CameraScannerWrapperView(scannedCode: .constant(nil)) { code in
                    referenceNumber = code.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: " ", with: "")
                    isScanning = false
                    initiateNewSearch()
                }
                .edgesIgnoringSafeArea(.all)
            }
            // NUEVO: hoja para asignar grouping/tracking unificado en caso de múltiples referencias o impresión
            .sheet(isPresented: $showGroupingSheet) {
                GroupingInputView(
                    grouping: $newGroupingValue,
                    confirmAction: {
                        assignGroupingIfNeeded(newGroupingValue)
                        showGroupingSheet = false
                        
                        // En caso de que se haya disparado desde el Printing,
                        // iniciamos la navegación al PrintView.
                        if selectedShipmentType == "Printing" {
                            shouldNavigateToPrint = true
                        }
                    },
                    cancelAction: {
                        showGroupingSheet = false
                    }
                )
            }
            // Validación al cambiar el Picker principal
            .onChange(of: selectedShipmentType) { newValue in
                if newValue == "Verification" || newValue == "Export" {
                    guard !referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        alertMessage = "You need a reference number to continue."
                        showAlert = true
                        selectedShipmentType = "More Information"
                        return
                    }
                    guard let data = apiResponse, !data.isEmpty else {
                        alertMessage = "No data found for the provided reference number."
                        showAlert = true
                        selectedShipmentType = "More Information"
                        return
                    }
                    storedTrackingData = data
                    if newValue == "Verification" {
                        shouldNavigateToChecklist = true
                    } else {
                        shouldNavigateToExportView = true
                    }
                }
            }
        }
    }

    // MARK: - Vistas Auxiliares

    /// Vista para la opción "More Information"
    private var moreInformationView: some View {
        Group {
            if isLoading {
                ProgressView("Loading data...")
            } else if let trackingData = apiResponse, !trackingData.isEmpty {
                VStack(spacing: 8) {
                    // Picker global para "Inbond" y "Domestic"
                    Picker(selection: $shipmentState.selectedInboundType, label: Text("Options")) {
                        Text("Inbond").tag("Inbond" as String?)
                        Text("Domestic").tag("Domestic" as String?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 8)
                    
                    MaterialListView(trackingData: storedTrackingData)
                        .frame(maxHeight: 300)
                        .padding(.horizontal, 8)
                }
            } else {
                Text("No data found.")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
        }
    }

    /// Vista del Menú Lateral
    private var sideMenuView: some View {
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
        .frame(width: 220)
        .padding(.horizontal, 8)
        .background(Color.white)
        .shadow(radius: 3)
    }
    
    // MARK: - Funciones de lógica

    /// Función para manejar el botón Print
    func handlePrintButton() {
        let trimmedReference = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedReference.isEmpty {
            alertMessage = "You need a reference number to continue."
            showAlert = true
            return
        }
        
        // Si ya hay datos, revisamos si falta grouping
        if let apiData = apiResponse, !apiData.isEmpty {
            // Checamos si hay al menos un item sin grouping o grouping vacío
            let missingGrouping = storedTrackingData.contains { item in
                item.grouping == nil || item.grouping!.isEmpty
            }
            
            if missingGrouping {
                // Pedimos el grouping
                showGroupingSheet = true
            } else {
                // Todos tienen grouping, vamos directo a imprimir
                shouldNavigateToPrint = true
            }
        } else {
            // Si no hay datos, hay que hacer la búsqueda primero
            initiateNewSearch()
        }
    }
    
    /// Función para iniciar la búsqueda (con múltiples o una sola referencia)
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
            let references = referenceNumber
                .split(separator: ",")
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
                    // **En lugar de mostrar “Nuevo Tracking”, ahora reutilizamos la misma hoja de grouping**
                    newGroupingValue = ""
                    showGroupingSheet = true
                }
            }
        } else {
            // Búsqueda individual con la referencia ingresada
            fetchAPIResponse()
        }
    }

    /// Búsqueda individual de la referencia (una sola)
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

    /// Búsquedas múltiples (cada referencia individual)
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
                        // Vamos agregando resultados a nuestro array global
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

    /// NUEVO: Función para asignar el “grouping” si está vacío o para consolidados
    func assignGroupingIfNeeded(_ groupingValue: String) {
        let trimmedGrouping = groupingValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGrouping.isEmpty else {
            alertMessage = "El campo de grouping no puede estar vacío."
            showAlert = true
            return
        }
        // Asignar a todos los items que no tengan grouping o sea vacío
        storedTrackingData = storedTrackingData.map { item in
            var newItem = item
            if newItem.grouping == nil || newItem.grouping!.isEmpty {
                newItem.grouping = trimmedGrouping
            }
            return newItem
        }
        apiResponse = storedTrackingData
        print("Grouping asignado: \(trimmedGrouping) a todos los materiales sin grouping.")
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}


// Extensión para ocultar teclado
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
