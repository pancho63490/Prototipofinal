import SwiftUI

struct ContentView: View {
    @State private var trackingNumber = ""
    @State private var invoiceNumber = ""
    @State private var facturaNumber = ""
    @State private var pallets = ""
    @State private var selectedShipmentType = "Domestic"
    @State private var shouldNavigateToPrint = false // Controla la navegación a la vista de impresión
    @State private var showAlert = false // Muestra la alerta si los campos están incompletos
    @State private var isMenuOpen = false // Controla si el menú lateral está abierto
    @State private var isScanning = false // Controla si se está escaneando
    @State private var currentField: String = ""
    @State private var selectedView: String? = nil // Maneja la navegación desde el menú

    let shipmentTypes = ["Domestic", "Inbound", "Tooling"]

    var body: some View {
        ZStack {
            // Contenido principal
            NavigationView {
                VStack(spacing: 20) {
                    // Logo y Nombre de la App
                    VStack {
                        Image(systemName: "shippingbox.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text("NixiScan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 40)
                    
                    // Formulario de entrada con botones para leer códigos de barras
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Tracking Number")
                            .font(.headline)
                        HStack {
                            TextField("Enter tracking number", text: $trackingNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            Button(action: {
                                currentField = "trackingNumber"
                                isScanning = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                        }

                        Text("Invoice Number")
                            .font(.headline)
                        HStack {
                            TextField("Enter invoice number", text: $invoiceNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            Button(action: {
                                currentField = "invoiceNumber"
                                isScanning = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                        }

                        Text("Factura Number")
                            .font(.headline)
                        HStack {
                            TextField("Enter factura number", text: $facturaNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            Button(action: {
                                currentField = "facturaNumber"
                                isScanning = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                        }

                        Text("Number of Pallets or Boxes")
                            .font(.headline)
                        TextField("Enter number of pallets or boxes", text: $pallets)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Shipment Type")
                            .font(.headline)
                        Picker("Select shipment type", selection: $selectedShipmentType) {
                            ForEach(shipmentTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Botón para iniciar el proceso de impresión
                    Button(action: {
                        // Validar que los campos estén completos antes de continuar
                        if trackingNumber.isEmpty || invoiceNumber.isEmpty || pallets.isEmpty || facturaNumber.isEmpty {
                            showAlert = true
                        } else {
                            shouldNavigateToPrint = true
                        }
                    }) {
                        Text("Imprimir")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Campos Incompletos"), message: Text("Por favor, completa todos los campos antes de continuar."), dismissButton: .default(Text("OK")))
                    }
                    
                    Spacer()

                    // Navegación a la vista de impresión
                    NavigationLink(destination: PrintView(trackingNumber: trackingNumber, invoiceNumber: invoiceNumber, pallets: pallets), isActive: $shouldNavigateToPrint) {
                        EmptyView()
                    }

                    // Navegación condicional a las vistas desde el menú
                    NavigationLink(destination: ReportView(), tag: "report", selection: $selectedView) {
                        EmptyView()
                    }
                    NavigationLink(destination: ContentView(), tag: "main", selection: $selectedView) {
                        EmptyView()
                    }
                }
                .navigationTitle("Impresión de Etiquetas")
                .navigationBarItems(leading: Button(action: {
                    withAnimation {
                        isMenuOpen.toggle() // Controlar apertura/cierre del menú
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                })
                .onTapGesture {
                    hideKeyboard()
                }
            }
            
            // Menú lateral que ocupa un cuarto de la pantalla
            SideMenuView(isMenuOpen: $isMenuOpen, selectedView: $selectedView)

            // Escáner de código de barras si está activo
            if isScanning {
                CameraScannerView(scannedCode: .constant(nil), onCodeScanned: { code in
                    insertScannedCode(code)
                    isScanning = false
                })
                .edgesIgnoringSafeArea(.all)
            }
        }
    }

    // Ocultar el teclado
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Insertar el código escaneado en el campo adecuado
    func insertScannedCode(_ code: String) {
        switch currentField {
        case "trackingNumber":
            trackingNumber = code
        case "invoiceNumber":
            invoiceNumber = code
        case "facturaNumber":
            facturaNumber = code
        default:
            break
        }
    }
}
