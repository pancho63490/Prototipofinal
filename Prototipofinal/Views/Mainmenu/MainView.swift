import SwiftUI

struct ContentView: View {
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
    @State private var useCustomLabels = false
    @State private var customLabels = 1
    @State private var objectIDsFromPrint: [String] = []
    @State private var shouldNavigateToExportView = false
    @State private var navigateToExportView = false
    let shipmentTypes = ["More Information", "Printing", "Verification", "Export"]
    let apiService = APIService()

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    AppHeader()

                    ReferenceInputView(referenceNumber: $referenceNumber, isScanning: $isScanning)
                        .onSubmit {
                            initiateNewSearch()
                        }

                    Picker("Tipo de opción", selection: $selectedShipmentType) {
                        ForEach(shipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Vista adicional basada en selección
                    if selectedShipmentType == "More Information" {
                        if isLoading {
                            ProgressView("Cargando datos...")
                        } else if let trackingData = apiResponse, !trackingData.isEmpty {
                            MaterialListView(trackingData: trackingData)
                        } else {
                            Text("No se encontraron datos.")
                                .foregroundColor(.gray)
                        }
                    } else if selectedShipmentType == "Printing" {
                        PrintingView(useCustomLabels: $useCustomLabels, customLabels: $customLabels)
                    } else if selectedShipmentType == "Verification" {
                        // No mostramos una vista específica aquí; la navegación se maneja mediante NavigationLink
                        EmptyView()
                    } else if selectedShipmentType == "Export" {
                        // No mostramos una vista específica aquí; la navegación se maneja mediante NavigationLink
                        EmptyView()
                    } else {
                        // Vista predeterminada para cualquier otra selección no manejada
                        EmptyView()
                    }

                    Spacer()

                    if isLoading && selectedShipmentType != "More Information" {
                        ProgressView("Cargando...")
                    }

                    // Botón "Imprimir" solo si está seleccionada la opción "Printing"
                    if selectedShipmentType == "Printing" {
                        Button(action: {
                            handlePrintButton()
                        }) {
                            Text("Imprimir \(useCustomLabels ? customLabels : uniqueObjectIDCount) etiquetas")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isLoading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isLoading || referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (apiResponse == nil || apiResponse!.isEmpty))
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                    }

                    // Texto de redirección para "Export"
                    if selectedShipmentType == "Export" {
                        Text("Redirigiendo a ExportView...")
                            .onAppear {
                                navigateToExportView = true
                            }
                    }

                    // NavigationLinks ocultos para navegación programática
                    NavigationLink(
                        destination: ExportView(),
                        isActive: $navigateToExportView,
                        label: { EmptyView() }
                    )

                    NavigationLink(
                        destination: PrintView(
                            referenceNumber: referenceNumber,
                            trackingData: storedTrackingData,
                            customLabels: customLabels,
                            useCustomLabels: useCustomLabels,
                            finalObjectIDs: $objectIDsFromPrint
                        ),
                        isActive: $shouldNavigateToPrint
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: MaterialChecklistView(
                            trackingData: storedTrackingData,
                            objectIDs: objectIDsFromPrint
                        ),
                        isActive: $shouldNavigateToChecklist
                    ) {
                        EmptyView()
                    }
                }
                .navigationTitle("Importación de Material")
                .padding()

                // Vista de escáner si está activo
                if isScanning {
                    VStack {
                        CameraScannerView(scannedCode: .constant(nil), onCodeScanned: { code in
                            referenceNumber = code
                            isScanning = false
                            initiateNewSearch()
                        })
                        .edgesIgnoringSafeArea(.all)

                        Button(action: {
                            isScanning = false
                        }) {
                            Text("Cancelar")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onChange(of: selectedShipmentType) { newValue in
                if newValue == "Verification" {
                    // Verificar si el número de referencia está vacío
                    if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "Necesitas un número de referencia para continuar."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revertir la selección
                    } else if apiResponse == nil || apiResponse!.isEmpty {
                        alertMessage = "No se encontraron datos para el número de referencia proporcionado."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revertir la selección
                    } else {
                        storedTrackingData = apiResponse ?? []
                        shouldNavigateToChecklist = true
                    }
                } else if newValue == "Export" {
                    // Verificar si el número de referencia está vacío antes de exportar
                    if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "Necesitas un número de referencia para continuar."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revertir la selección
                    } else if apiResponse == nil || apiResponse!.isEmpty {
                        alertMessage = "No se encontraron datos para el número de referencia proporcionado."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revertir la selección
                    } else {
                        shouldNavigateToExportView = true
                    }
                }
            }
        }
    }

    // Función para iniciar una nueva búsqueda, reseteando estados anteriores
    func initiateNewSearch() {
        // Resetear estados anteriores
        self.apiResponse = nil
        self.storedTrackingData = []
        self.uniqueObjectIDs = []
        self.uniqueObjectIDCount = 0
        self.objectIDsFromPrint = []
        self.showAlert = false
        self.alertMessage = ""

        // Iniciar nueva búsqueda
        fetchAPIResponse()
    }

    // Función para manejar la acción del botón "Imprimir"
    func handlePrintButton() {
        // Verificar si el número de referencia está vacío
        if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Necesitas un número de referencia para continuar."
            showAlert = true
            return
        }

        if apiResponse != nil && !(apiResponse?.isEmpty ?? true) {
            shouldNavigateToPrint = true
        } else {
            initiateNewSearch()
        }
    }

    // Función para llamar a la API y procesar la respuesta
    func fetchAPIResponse() {
        guard !referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.alertMessage = "Por favor, completa el número de referencia antes de continuar."
            self.showAlert = true
            return
        }

        isLoading = true
        apiService.fetchData(referenceNumber: referenceNumber) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let trackingData):
                    if trackingData.isEmpty {
                        self.alertMessage = "No se encontraron datos para el número de referencia proporcionado."
                        self.showAlert = true
                    } else {
                        self.apiResponse = trackingData
                        self.storedTrackingData = trackingData // Guarda los datos permanentemente

                        // Extraer IDs únicos usando externalDeliveryID (o algún otro campo disponible en tu JSON)
                        let uniqueIDsSet = Set(trackingData.map { $0.externalDeliveryID })
                        self.uniqueObjectIDs = Array(uniqueIDsSet)
                        self.uniqueObjectIDCount = uniqueObjectIDs.count
                    }

                case .failure(let error):
                    // Diferenciar entre tipos de errores
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .notFound:
                            self.alertMessage = "No se encontraron datos para el número de referencia proporcionado."
                        case .serverError:
                            self.alertMessage = "Error del servidor. Por favor, intenta nuevamente más tarde."
                        default:
                            self.alertMessage = "Ocurrió un error: \(error.localizedDescription)"
                        }
                    } else {
                        self.alertMessage = "Ocurrió un error: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                }
            }
        }
    }

    // Ocultar el teclado
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
