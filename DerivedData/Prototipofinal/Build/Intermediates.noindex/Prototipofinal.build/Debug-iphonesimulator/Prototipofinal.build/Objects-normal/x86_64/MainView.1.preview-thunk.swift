import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/Mainmenu/MainView.swift", line: 1)
import SwiftUI

struct ContentView: View {
    @State private var referenceNumber = ""
    @State private var selectedShipmentType = "More Information"
    @State private var shouldNavigateToPrint = false
    @State private var shouldNavigateToChecklist = false // Nueva variable para manejar la navegación a MaterialChecklistView
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var isScanning = false
    @State private var apiResponse: [TrackingData]? // Datos de la API
    @State private var storedTrackingData: [TrackingData] = [] // Almacena los datos de tracking
    @State private var uniqueObjectIDCount: Int = 0 // Cuenta los Object IDs únicos
    @State private var uniqueObjectIDs: [String] = [] // Object IDs únicos
    @State private var useCustomLabels = false // Bandera para indicar si se usarán etiquetas personalizadas
    @State private var customLabels = 1 // Cantidad personalizada de etiquetas
    @State private var objectIDsFromPrint: [String] = [] // Para almacenar los Object IDs generados en PrintView
    @State private var shouldNavigateToExportView = false
    @State private var navigateToExportView = false
    let shipmentTypes = ["More Information", "Printing", "Verification","Export"]
    let apiService = APIService() // Instancia del servicio de API

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: __designTimeInteger("#3115_0", fallback: 20)) {
                    AppHeader()

                    // Formulario de entrada con un botón para escanear códigos de barras
                    ReferenceInputView(referenceNumber: $referenceNumber, isScanning: $isScanning)
                        .onSubmit {
                            fetchAPIResponse() // Llama a la API cuando el usuario termina de escribir
                        }

                    // Selector de opción
                    Picker(__designTimeString("#3115_1", fallback: "Tipo de opción"), selection: $selectedShipmentType) {
                        ForEach(shipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Vista adicional basada en selección
                    if selectedShipmentType == __designTimeString("#3115_2", fallback: "More Information") {
                        if let trackingData = apiResponse {
                            MaterialListView(trackingData: trackingData) // Muestra los datos cuando hay una respuesta
                        } else {
                            Text(__designTimeString("#3115_3", fallback: "Cargando datos...")) // Mensaje mientras carga
                        }
                    } else if selectedShipmentType == __designTimeString("#3115_4", fallback: "Printing") {
                        PrintingView(useCustomLabels: $useCustomLabels, customLabels: $customLabels) // Muestra la vista de impresión
                    }

                    Spacer()

                    // Indicador de carga
                    if isLoading {
                        ProgressView(__designTimeString("#3115_5", fallback: "Cargando..."))
                    }

                    // Mostrar el botón "Imprimir" solo si está seleccionada la opción "Printing"
                    if selectedShipmentType == __designTimeString("#3115_6", fallback: "Printing") {
                        Button(action: {
                            if referenceNumber.isEmpty {
                                showAlert = __designTimeBoolean("#3115_7", fallback: true)
                            } else if apiResponse != nil {
                                // Si ya hay respuesta de la API, permitir la impresión
                                shouldNavigateToPrint = __designTimeBoolean("#3115_8", fallback: true)
                            } else {
                                // Si no hay respuesta, llamar a la API
                                isLoading = __designTimeBoolean("#3115_9", fallback: true)
                                fetchAPIResponse()
                            }
                        })
                        // Mostrar el botón "Imprimir" solo si está seleccionada la opción "Printing"
              

                        
                        {
                            Text("Imprimir \(useCustomLabels ? customLabels : uniqueObjectIDCount) etiquetas")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isLoading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(__designTimeInteger("#3115_10", fallback: 10))
                        }
                        .disabled(isLoading || referenceNumber.isEmpty) // Deshabilitar durante la carga o si falta la referencia
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text(__designTimeString("#3115_11", fallback: "Campos Incompletos")), message: Text(__designTimeString("#3115_12", fallback: "Por favor, completa el número de referencia antes de continuar.")), dismissButton: .default(Text(__designTimeString("#3115_13", fallback: "OK"))))
                        }
                    }
                    // Activar la navegación automáticamente si se selecciona "Export"
                            if selectedShipmentType == __designTimeString("#3115_14", fallback: "Export") {
                                Text(__designTimeString("#3115_15", fallback: "Redirigiendo a ExportView..."))
                                    .onAppear {
                                        navigateToExportView = __designTimeBoolean("#3115_16", fallback: true) // Activar la navegación
                                    }
                            }
                    NavigationLink(
                                        destination: ExportView(),
                                        isActive: $navigateToExportView,
                                        label: { EmptyView() }
                                    )

                    // Navegación a la vista de impresión solo si el botón "Imprimir" fue presionado
                    NavigationLink(
                        destination: PrintView(
                            referenceNumber: referenceNumber,
                            trackingData: storedTrackingData, // Usamos storedTrackingData
                            customLabels: customLabels,
                            useCustomLabels: useCustomLabels,
                            finalObjectIDs: $objectIDsFromPrint // Recibe los Object IDs generados en PrintView
                        ),
                        isActive: $shouldNavigateToPrint
                    ) {
                        EmptyView()
                    }

                    // Navegación a la vista de verificación de materiales
                    NavigationLink(
                        destination: MaterialChecklistView(
                            trackingData: storedTrackingData, // Pasar siempre storedTrackingData
                            objectIDs: objectIDsFromPrint
                        ),
                        isActive: $shouldNavigateToChecklist
                    ) {
                        EmptyView()
                    }
                }
                .navigationTitle(__designTimeString("#3115_17", fallback: "Importación de Material"))
                .padding()

                // Escáner de código de barras si está activo
                if isScanning {
                    VStack {
                        CameraScannerView(scannedCode: .constant(nil), onCodeScanned: { code in
                            referenceNumber = code // Asigna el código escaneado a referenceNumber
                            isScanning = __designTimeBoolean("#3115_18", fallback: false)
                            fetchAPIResponse() // Llama a la API al escanear
                        })
                        .edgesIgnoringSafeArea(.all)

                        // Botón de cancelar
                        Button(action: {
                            isScanning = __designTimeBoolean("#3115_19", fallback: false)
                        }) {
                            Text(__designTimeString("#3115_20", fallback: "Cancelar"))
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(__designTimeInteger("#3115_21", fallback: 10))
                        }
                        .padding(.top, __designTimeInteger("#3115_22", fallback: 20))
                    }
                }
            }
            .onTapGesture {
                hideKeyboard() // Ocultar teclado al tocar fuera del campo
            }
            // Navegar automáticamente cuando se selecciona "Verification"
            .onChange(of: selectedShipmentType) { newValue in
                if newValue == __designTimeString("#3115_23", fallback: "Verification") {
                    storedTrackingData = apiResponse ?? []
                    shouldNavigateToChecklist = __designTimeBoolean("#3115_24", fallback: true)
                }
            }
        }
    }

    // Función para llamar a la API y procesar la respuesta
    func fetchAPIResponse() {
        guard !referenceNumber.isEmpty else {
            self.showAlert = __designTimeBoolean("#3115_25", fallback: true)
            return
        }

        isLoading = __designTimeBoolean("#3115_26", fallback: true)
        apiService.fetchData(referenceNumber: referenceNumber) { result in
            DispatchQueue.main.async {
                self.isLoading = __designTimeBoolean("#3115_27", fallback: false)
                switch result {
                case .success(let trackingData):
                    self.apiResponse = trackingData
                    self.storedTrackingData = trackingData // Guarda los datos permanentemente

                    // Extraer IDs únicos usando externalDeliveryID (o algún otro campo disponible en tu JSON)
                    let uniqueIDsSet = Set(trackingData.map { $0.externalDeliveryID })
                    self.uniqueObjectIDs = Array(uniqueIDsSet)
                    self.uniqueObjectIDCount = uniqueObjectIDs.count
                    
                case .failure(let error):
                    print("API Error: \(error.localizedDescription)")
                    self.showAlert = __designTimeBoolean("#3115_28", fallback: true)
                }
            }
        }
    }

    // Ocultar el teclado
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
