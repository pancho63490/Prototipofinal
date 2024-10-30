import SwiftUI

struct ManualInsertionView: View {
    // Variables de estado para External Delivery ID y Supplier Name
    @State private var externalDeliveryID = ""
    @State private var supplierName = ""
    
    // Lista de materiales
    @State private var materials: [Material] = []
    @State private var showingAddMaterialSheet = false
    
    // Variables para alertas y mensajes de error
    @State private var alertItem: AlertItem?
    
    // Indicador de carga
    @State private var isLoading = false
    
    // Environment para manejar la presentación
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Título de la aplicación
            VStack {
                Image(systemName: "shippingbox.fill") // Reemplaza con tu logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("NixiScan")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Información de la External Delivery ID y Supplier Name
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Información de Entrega")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "doc.text", title: "ID de Entrega Externa", text: $externalDeliveryID)
                        
                        CustomTextFieldWithIcon(icon: "person.crop.circle", title: "Nombre del Proveedor", text: $supplierName)
                    }
                    
                    // Sección de Materiales
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lista de Materiales")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Lista de materiales agregados
                        ForEach(materials) { material in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Código: \(material.code)")
                                        .fontWeight(.bold)
                                    Text("Cantidad: \(material.quantity)")
                                }
                                Spacer()
                                Button(action: {
                                    deleteMaterial(material)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
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
                                Text("Agregar Material")
                            }
                        }
                        .sheet(isPresented: $showingAddMaterialSheet) {
                            // Hoja para agregar material
                            AddMaterialSheet(materials: $materials)
                        }
                    }
                    
                    // Botón de enviar
                    Button(action: {
                        hideKeyboard()
                        submitData()
                    }) {
                        Text("Enviar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // Indicador de carga
                    if isLoading {
                        ProgressView("Enviando datos...")
                            .padding()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Ingreso Manual de Datos")
        .alert(item: $alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK")) {
                    if alertItem.title == "Éxito" {
                        // Navegar de regreso después de 2 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            )
        }
        .onTapGesture {
            hideKeyboard() // Ocultar el teclado al tocar fuera
        }
    }
    
    // Función para eliminar un material
    private func deleteMaterial(_ material: Material) {
        if let index = materials.firstIndex(where: { $0.id == material.id }) {
            materials.remove(at: index)
        }
    }
    
    // Función para enviar los datos a la API
    private func submitData() {
        // Validación de campos obligatorios
        if externalDeliveryID.isEmpty ||
            supplierName.isEmpty ||
            materials.isEmpty {
            alertItem = AlertItem(title: "Error", message: "Por favor, completa todos los campos obligatorios.")
            return
        }
        
        isLoading = true
        
        // Crear los objetos TrackingData
        let trackingDataList = materials.map { material in
            TrackingData(
                externalDeliveryID: externalDeliveryID,
                material: material.code,
                deliveryQty: material.quantity,
                deliveryNo: "0",
                supplierVendor: "0",
                supplierName: supplierName,
                container: nil,
                src: "Manual" // Asignar "Manual" según tu requerimiento
            )
        }
        
        // Enviar cada TrackingData a la API
        let group = DispatchGroup()
        var encounteredError: Error?
        
        for trackingData in trackingDataList {
            group.enter()
            DeliveryAPIService.shared.sendTrackingData(trackingData) { result in
                switch result {
                case .success():
                    print("TrackingData enviado exitosamente: \(trackingData)")
                case .failure(let error):
                    print("Error al enviar TrackingData: \(error.localizedDescription)")
                    encounteredError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            if let error = encounteredError {
                alertItem = AlertItem(title: "Error", message: "Error al enviar datos: \(error.localizedDescription)")
            } else {
                alertItem = AlertItem(title: "Éxito", message: "Datos enviados exitosamente.")
                clearFields()
            }
        }
    }
    
    // Función para limpiar los campos después de enviar
    private func clearFields() {
        externalDeliveryID = ""
        supplierName = ""
        materials.removeAll()
    }
    
    // Función para ocultar el teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Custom Text Field with Icon
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
    
    // Estructura para Material
    struct Material: Identifiable {
        let id = UUID()
        var code: String
        var quantity: String
    }
    
    // Vista para Agregar Material (Simplificada)
    struct AddMaterialSheet: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var materials: [Material]
        
        @State private var materialCode = ""
        @State private var quantity = ""
        
        // Para el escáner de cámara
        @State private var isShowingScanner = false
        @State private var isShowingQuantityScanner = false
        
        // NumberFormatter para validar cantidad
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
        }()
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    // Código del Material
                    HStack {
                        CustomTextFieldWithIcon(icon: "barcode.viewfinder", title: "Código del Material", text: $materialCode)
                        
                        Button(action: {
                            // Abrir escáner para código
                            isShowingScanner = true
                        }) {
                            Image(systemName: "camera")
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .sheet(isPresented: $isShowingScanner) {
                            // Usamos tu método existente CameraScannerView
                            CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                                materialCode = code
                                isShowingScanner = false
                            })
                        }
                    }
                    
                    // Cantidad
                    HStack {
                        CustomTextFieldWithIcon(icon: "number", title: "Cantidad", text: $quantity, keyboardType: .numberPad)
                        
                        Button(action: {
                            // Abrir escáner para cantidad
                            isShowingQuantityScanner = true
                        }) {
                            Image(systemName: "camera")
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .sheet(isPresented: $isShowingQuantityScanner) {
                            // Usamos tu método existente CameraScannerView
                            CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { scannedQuantity in
                                // Validar que la cantidad escaneada sea numérica
                                if let _ = numberFormatter.number(from: scannedQuantity) {
                                    quantity = scannedQuantity
                                }
                                isShowingQuantityScanner = false
                            })
                        }
                    }
                    
                    // Botón para agregar material
                    Button(action: {
                        // Agregar material a la lista si la cantidad es numérica
                        if let _ = numberFormatter.number(from: quantity), !materialCode.isEmpty {
                            let newMaterial = Material(code: materialCode, quantity: quantity)
                            materials.append(newMaterial)
                            // Limpiar campos
                            materialCode = ""
                            quantity = ""
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            // Mostrar error si la cantidad no es válida
                            // Puedes implementar una alerta aquí si lo deseas
                        }
                    }) {
                        Text("Agregar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((materialCode.isEmpty || quantity.isEmpty || numberFormatter.number(from: quantity) == nil) ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(materialCode.isEmpty || quantity.isEmpty || numberFormatter.number(from: quantity) == nil)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Agregar Material")
                .navigationBarItems(trailing: Button("Cancelar") {
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
struct AlertItem: Identifiable {
    var id = UUID()
    var title: String
    var message: String
}
