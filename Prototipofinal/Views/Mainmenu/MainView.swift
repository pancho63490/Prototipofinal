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
    @State private var shouldNavigateToManualInsertion = false
    @State private var showManualInsertionAlert = false
    @State private var navigateToLogisticsVerificationView = false// Added to control the new alert
    let shipmentTypes = ["More Information", "Printing", "Verification","Logis", "Export"]
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
                        .onChange(of: referenceNumber) { newValue in
                            referenceNumber = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }

                    Picker("Option Type", selection: $selectedShipmentType) {
                        ForEach(shipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Additional view based on selection
                    if selectedShipmentType == "More Information" {
                        if isLoading {
                            ProgressView("Loading data...")
                        } else if let trackingData = apiResponse, !trackingData.isEmpty {
                            MaterialListView(trackingData: trackingData)
                        } else {
                            Text("No data found.")
                                .foregroundColor(.gray)
                        }
                    } else if selectedShipmentType == "Printing" {
                        PrintingView(useCustomLabels: $useCustomLabels, customLabels: $customLabels)
                    } else if selectedShipmentType == "Verification" {
                        EmptyView()
                    } else if selectedShipmentType == "Logis"{
                        EmptyView()
                    }
                    else if selectedShipmentType == "Export" {
                        EmptyView()
                    } else {
                        EmptyView()
                    }

                    Spacer()
                        
                    if isLoading && selectedShipmentType != "More Information" {
                        ProgressView("Loading...")
                    }

                    // "Print" button only if the "Printing" option is selected
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
                        .disabled(isLoading || referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (apiResponse == nil || apiResponse!.isEmpty))
                    }

                    // Redirect text for "Export"
                    if selectedShipmentType == "Export" {
                        Text("Redirecting to ExportView...")
                            .onAppear {
                                navigateToExportView = true
                            }
                    }
                    if selectedShipmentType == "Logis" {
                        Text("Redirecting to LogisView...")
                            .onAppear {
                                navigateToLogisticsVerificationView = true
                            }
                    }
                    
                    NavigationLink(
                        destination: ManualInsertionView(),
                        isActive: $shouldNavigateToManualInsertion
                    ) {
                        EmptyView()
                    }

                    // Hidden NavigationLinks for programmatic navigation
                    NavigationLink(
                        destination: LogisticsVerificationView(),
                        isActive: $navigateToLogisticsVerificationView,
                        label: { EmptyView() }
                    )
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
                .navigationTitle("Material Import")
                .padding()
                // Move alert modifiers here
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showManualInsertionAlert) {
                    Alert(
                        title: Text("No data found"),
                        message: Text("Would you like to enter data manually?"),
                        primaryButton: .default(Text("Yes"), action: {
                            shouldNavigateToManualInsertion = true
                        }),
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                        
                // Scanner view if active
                if isScanning {
                    VStack {
                        CameraScannerView(scannedCode: .constant(nil), onCodeScanned: { code in
                            referenceNumber = code.trimmingCharacters(in: .whitespacesAndNewlines) // Trim el código escaneado
                            isScanning = false
                            initiateNewSearch()
                        })
                        .edgesIgnoringSafeArea(.all)

                        Button(action: {
                            isScanning = false
                        }) {
                            Text("Cancel")
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
                    // Check if the reference number is empty
                    if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "You need a reference number to continue."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revert selection
                    } else if apiResponse == nil || apiResponse!.isEmpty {
                        alertMessage = "No data found for the provided reference number."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revert selection
                    } else {
                        storedTrackingData = apiResponse ?? []
                        shouldNavigateToChecklist = true
                    }
                } else if newValue == "Export" {
                    // Check if the reference number is empty before exporting
                    if referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "You need a reference number to continue."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revert selection
                    } else if apiResponse == nil || apiResponse!.isEmpty {
                        alertMessage = "No data found for the provided reference number."
                        showAlert = true
                        selectedShipmentType = "More Information" // Revert selection
                    } else {
                        shouldNavigateToExportView = true
                    }
                }
            }
        }
    }

    // Function to initiate a new search, resetting previous states
    func initiateNewSearch() {
        referenceNumber = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
          
        self.apiResponse = nil
        self.storedTrackingData = []
        self.uniqueObjectIDs = []
        self.uniqueObjectIDCount = 0
        self.objectIDsFromPrint = []
        self.showAlert = false
        self.alertMessage = ""
        self.showManualInsertionAlert = false // Reset alert state

        // Start new search
        fetchAPIResponse()
    }

    // Function to handle the "Print" button action
    func handlePrintButton() {
        // Trim the reference number
        let trimmedReference = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the reference number is empty
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

    func fetchAPIResponse() {
            // Trim el referenceNumber y asignarlo de nuevo
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
                            // Mostrar alerta para preguntar si desean navegar a ManualInsertionView
                            self.showManualInsertionAlert = true
                            print("Debug: No data found. Asking user if they want to enter data manually.")
                        } else {
                            self.apiResponse = trackingData
                            self.storedTrackingData = trackingData // Guardar datos permanentemente

                            // Extraer IDs únicos usando externalDeliveryID
                            let uniqueIDsSet = Set(trackingData.map { $0.externalDeliveryID })
                            self.uniqueObjectIDs = Array(uniqueIDsSet)
                            self.uniqueObjectIDCount = uniqueObjectIDs.count
                            print("Debug: Found \(self.uniqueObjectIDCount) unique IDs.")
                        }

                    case .failure(let error):
                        // Manejar errores de red o de decodificación
                        self.alertMessage = "An error occurred: \(error.localizedDescription)"
                        self.showAlert = true
                        print("Debug: An error occurred: \(error.localizedDescription).")
                    }
                }
            }
        }
    // Hide the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
