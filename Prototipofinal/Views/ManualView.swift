import SwiftUI

/// Enum para manejar los diferentes tipos de alerta que podemos mostrar
enum ActiveAlertType: Identifiable {
    case confirmation       // Para "¿Estás seguro?"
    case success(String)    // Para mostrar mensajes de éxito
    case error(String)      // Para mostrar mensajes de error
    
    // Necesario para conformar al protocolo Identifiable
    var id: Int {
        switch self {
        case .confirmation:
            return 0
        case .success:
            return 1
        case .error:
            return 2
        }
    }
}

struct ManualInsertionView: View {
    // State variables para la entrega y el proveedor
    @State private var externalDeliveryID = ""
    @State private var supplierName = ""
    
    // Escáner
    @State private var isShowingExternalDeliveryIDScanner = false
    @State private var isShowingSupplierNameScanner = false
    
    // Lista de materiales
    @State private var materials: [Material] = []
    @State private var showingAddMaterialSheet = false
    
    // Indicador de carga
    @State private var isLoading = false
    
    // Manejo de la alerta unificada
    @State private var activeAlert: ActiveAlertType? = nil
    
    // Environment para navegar o cerrar la vista
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Título / Logo
            VStack {
                Banner()
                Image(systemName: "shippingbox.fill") // Ícono a tu gusto
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("XDOCK")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Sección de información de Entrega
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery Information")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // External Delivery ID + Botón de Cámara
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "doc.text",
                                title: "External Delivery ID",
                                text: $externalDeliveryID
                            )
                            
                            Button(action: {
                                isShowingExternalDeliveryIDScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingExternalDeliveryIDScanner) {
                                // Implementa tu vista de scanner aquí
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { code in
                                        externalDeliveryID = code
                                        isShowingExternalDeliveryIDScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Supplier Name + Botón de Cámara
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "person.crop.circle",
                                title: "Supplier Name",
                                text: $supplierName
                            )
                            
                            Button(action: {
                                isShowingSupplierNameScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingSupplierNameScanner) {
                                // Implementa tu vista de scanner aquí
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { code in
                                        supplierName = code
                                        isShowingSupplierNameScanner = false
                                    }
                                )
                            }
                        }
                    }
                    
                    // Sección de Materiales
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Materials List")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Lista de materiales agregados
                        ForEach(materials) { material in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Code: \(material.code)")
                                            .fontWeight(.bold)
                                        Text("Quantity: \(material.quantity) \(material.unit)")
                                    }
                                    Spacer()
                                    Button(action: {
                                        deleteMaterial(material)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                HStack {
                                    Text("Gross Weight: \(material.grossWeight) \(material.weightUnit)")
                                    Spacer()
                                    Text("Net Weight: \(material.netWeight) \(material.weightUnit)")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Botón para agregar material
                        Button(action: {
                            showingAddMaterialSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Material")
                            }
                        }
                        .sheet(isPresented: $showingAddMaterialSheet) {
                            // Sheet para agregar material
                            AddMaterialSheet(materials: $materials)
                        }
                    }
                    
                    // Botón de "Send"
                    Button(action: {
                        hideKeyboard()
                        // Disparamos la alerta de confirmación
                        activeAlert = .confirmation
                    }) {
                        Text("Send")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // Indicador de carga
                    if isLoading {
                        ProgressView("Sending data...")
                            .padding()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Manual Data Entry")
        /// ÚNICO Alert
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .confirmation:
                return Alert(
                    title: Text("Are you sure?"),
                    message: Text("Are you sure you want to send this data?"),
                    primaryButton: .destructive(Text("Send")) {
                        submitData()
                    },
                    secondaryButton: .cancel()
                )
                
            case .success(let message):
                return Alert(
                    title: Text("Success"),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        // Navega atrás después de 2 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
                
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onTapGesture {
            hideKeyboard() // Ocultar teclado al pulsar fuera
        }
    }
    
    // MARK: - Funciones
    
    /// Eliminar un material de la lista
    private func deleteMaterial(_ material: Material) {
        if let index = materials.firstIndex(where: { $0.id == material.id }) {
            materials.remove(at: index)
        }
    }
    
    /// Llamado cuando el usuario confirma enviar datos
    private func submitData() {
        // Validar campos requeridos
        if externalDeliveryID.isEmpty || supplierName.isEmpty || materials.isEmpty {
            activeAlert = .error("Please complete all required fields.")
            return
        }
        
        isLoading = true
        
        // Crear TrackingData2 para cada material
        let trackingDataList = materials.map { material in
            TrackingData2(
                externalDeliveryID: externalDeliveryID,
                material: material.code,
                deliveryQty: material.quantity,
                deliveryNo: externalDeliveryID,
                supplierVendor: "0",
                supplierName: supplierName,
                container: "x",
                src: "Manual",
                unit: material.unit,           // Unidad de cantidad (ej. "pcs", "KG", "LB")
                grossWeight: material.grossWeight,
                netWeight: material.netWeight,
                weightUnit: material.weightUnit // Unidad de peso (ej. "KG" o "LB")
            )
        }
        
        // Enviar cada TrackingData2 al API (asincrono)
        let group = DispatchGroup()
        var encounteredError: Error?
        
        for trackingData in trackingDataList {
            group.enter()
            DeliveryAPIService.shared.sendTrackingData(trackingData) { result in
                switch result {
                case .success():
                    print("TrackingData sent successfully: \(trackingData)")
                case .failure(let error):
                    print("Error sending TrackingData: \(error.localizedDescription)")
                    encounteredError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            if let error = encounteredError {
                self.activeAlert = .error("Error sending data: \(error.localizedDescription)")
            } else {
                self.activeAlert = .success("Data sent successfully.")
                self.clearFields()
            }
        }
    }
    
    /// Limpiar campos tras enviar
    private func clearFields() {
        externalDeliveryID = ""
        supplierName = ""
        materials.removeAll()
    }
    
    /// Ocultar teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
    
    // MARK: - Subvistas y modelos
    
    /// Custom TextField con ícono a la izquierda
    struct CustomTextFieldWithIcon: View {
        var icon: String
        var title: String
        @Binding var text: String
        var keyboardType: UIKeyboardType = .default
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.leading, 10)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    /// Modelo de material
    struct Material: Identifiable {
        let id = UUID()
        var code: String
        var quantity: String
        var unit: String           // Unidad de cantidad (ej. "pcs", "KG", "LB")
        var grossWeight: String
        var netWeight: String
        var weightUnit: String     // Unidad de peso (ej. "KG" o "LB")
    }
    
    /// Sheet para agregar un nuevo material
    // Sheet para agregar un nuevo material
    struct AddMaterialSheet: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var materials: [Material]
        
        @State private var materialCode = ""
        @State private var quantity = ""
        // Valor predeterminado para unidad de cantidad
        @State private var selectedUnit = "pcs"
        @State private var grossWeight = ""
        @State private var netWeight = ""
        // Valor predeterminado para unidad de peso
        @State private var weightUnit = "LB"
        
        // Opciones para la unidad de cantidad y peso
        let units = ["pcs", "KG", "LB"]
        let weightUnits = ["KG", "LB"]
        
        // Escáneres individuales
        @State private var isShowingScanner = false
        @State private var isShowingQuantityScanner = false
        @State private var isShowingGrossWeightScanner = false
        @State private var isShowingNetWeightScanner = false
        
        // Validador de números
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Código de material
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "barcode.viewfinder",
                                title: "Material Code",
                                text: $materialCode
                            )
                            
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { code in
                                        materialCode = code
                                        isShowingScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Cantidad
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "number",
                                title: "Quantity",
                                text: $quantity,
                                keyboardType: .decimalPad
                            )
                            
                            Button(action: {
                                isShowingQuantityScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingQuantityScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { scannedQuantity in
                                        // Validar que sea numérico
                                        if let _ = numberFormatter.number(from: scannedQuantity) {
                                            quantity = scannedQuantity
                                        }
                                        isShowingQuantityScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Picker para Unidad de Medida (cantidad)
                        Picker("Unit of Measurement", selection: $selectedUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Campo de Net Weight (primero)
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "scalemass.fill",
                                title: "Net Weight",
                                text: $netWeight,
                                keyboardType: .decimalPad
                            )
                            // Al cambiar el netWeight, actualizar el grossWeight automáticamente
                            .onChange(of: netWeight) { newValue in
                                if let net = Double(newValue) {
                                    let addition = (weightUnit == "KG") ? 13.65 : 30.10
                                    grossWeight = String(format: "%.2f", net + addition)
                                }
                            }
                            
                            Button(action: {
                                isShowingNetWeightScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingNetWeightScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { scannedNetWeight in
                                        if let _ = numberFormatter.number(from: scannedNetWeight) {
                                            netWeight = scannedNetWeight
                                        }
                                        isShowingNetWeightScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Campo de Gross Weight (luego)
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "scalemass",
                                title: "Gross Weight",
                                text: $grossWeight,
                                keyboardType: .decimalPad
                            )
                            
                            Button(action: {
                                isShowingGrossWeightScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingGrossWeightScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { scannedGrossWeight in
                                        if let _ = numberFormatter.number(from: scannedGrossWeight) {
                                            grossWeight = scannedGrossWeight
                                        }
                                        isShowingGrossWeightScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Picker para Unidad de Peso General
                        Picker("Weight Unit", selection: $weightUnit) {
                            ForEach(weightUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        // Al cambiar la unidad de peso, actualizar también el grossWeight
                        .onChange(of: weightUnit) { newValue in
                            if let net = Double(netWeight) {
                                let addition = (newValue == "KG") ? 13.65 : 30.10
                                grossWeight = String(format: "%.2f", net + addition)
                            }
                        }
                        
                        // Botón "Add"
                        Button(action: {
                            // Validar campos numéricos y no vacíos
                            if let _ = numberFormatter.number(from: quantity),
                               let _ = numberFormatter.number(from: grossWeight),
                               let _ = numberFormatter.number(from: netWeight),
                               !materialCode.isEmpty {
                                
                                let newMaterial = Material(
                                    code: materialCode,
                                    quantity: quantity,
                                    unit: selectedUnit,
                                    grossWeight: grossWeight,
                                    netWeight: netWeight,
                                    weightUnit: weightUnit
                                )
                                materials.append(newMaterial)
                                
                                // Limpieza de campos y reseteo de valores a los predeterminados
                                materialCode = ""
                                quantity = ""
                                grossWeight = ""
                                netWeight = ""
                                selectedUnit = "pcs" // Valor predeterminado para unidad de cantidad
                                weightUnit = "LB"   // Valor predeterminado para unidad de peso
                                
                                // Cerrar sheet
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                // Opcional: mostrar una alerta de error si faltan datos
                            }
                        }) {
                            Text("Add")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (materialCode.isEmpty ||
                                     quantity.isEmpty ||
                                     grossWeight.isEmpty ||
                                     netWeight.isEmpty ||
                                     numberFormatter.number(from: quantity) == nil ||
                                     numberFormatter.number(from: grossWeight) == nil ||
                                     numberFormatter.number(from: netWeight) == nil)
                                    ? Color.gray : Color.blue
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(
                            materialCode.isEmpty ||
                            quantity.isEmpty ||
                            grossWeight.isEmpty ||
                            netWeight.isEmpty ||
                            numberFormatter.number(from: quantity) == nil ||
                            numberFormatter.number(from: grossWeight) == nil ||
                            numberFormatter.number(from: netWeight) == nil
                        )
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Add Material")
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }

    
    struct ManualInsertionView_Previews: PreviewProvider {
        static var previews: some View {
            ManualInsertionView()
        }
    }
}

/// Modelo para enviar al API
struct TrackingData2: Codable {
    let externalDeliveryID: String
    let material: String
    let deliveryQty: String
    let deliveryNo: String
    let supplierVendor: String
    let supplierName: String
    let container: String?
    let src: String?
    let unit: String?
    let grossWeight: String?
    let netWeight: String?
    let weightUnit: String? // Unidad de peso general
    
    // Mapeo a keys JSON
    enum CodingKeys: String, CodingKey {
        case externalDeliveryID = "EXTERNAL_DELVRY_ID"
        case material = "MATERIAL"
        case deliveryQty = "DELIVERY_QTY"
        case deliveryNo = "DELIVERY_NO"
        case supplierVendor = "SUPPLIER_VENDOR"
        case supplierName = "SUPPLIER_NAME"
        case container = "CONTAINER"
        case src = "SRC"
        case unit = "UNIT"
        case grossWeight = "PESO_BRUTO"
        case netWeight = "PESO_NETO"
        case weightUnit = "UNIDAD_PESO"
    }
}
