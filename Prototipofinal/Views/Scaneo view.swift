/*import SwiftUI
struct MaterialChecklistView: View {
    var trackingData: [TrackingData] // Recibe la lista de TrackingData desde la API
    
    @Environment(\.presentationMode) var presentationMode // Para navegar de vuelta
    
    @State private var isShowingCameraScannerForLocation = false
    @State private var isShowingCameraScannerForMaterial = false
    @State private var isShowingMaterialEntry = false
    @State private var selectedObjectIndex: Int? = nil
    @State private var selectedMaterial: String = "" // Material seleccionado
    @State private var enteredQuantity: String = "" // Cantidad ingresada
    @State private var scannedLocation: String? = nil // Guardar la locación escaneada
    @State private var scannedMaterial: String? = nil // Para almacenar el material escaneado
    
    @State private var groupedObjects: [GroupedObject] = [] // Lista mutable de objetos agrupados
    
    @State private var showIncompleteAlert = false
    @State private var showSuccessAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Encabezado minimalista con logo pequeño y nombre de la aplicación
                VStack {
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                    
                    Text("NixiScan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                List {
                    ForEach(groupedObjects.indices, id: \.self) { index in
                        let group = groupedObjects[index]
                        Section(header: headerView(for: group)) {
                            contentView(for: group, index: index)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .background(Color.gray.opacity(0.1))
                
                // Botón de Enviar para mandar los datos completados a la API
                enviarButton
                    .padding()
            }
            .background(Color.white)
            .navigationTitle("Listado de Materiales")
            .onAppear {
                // Agrupar los `trackingData` por `objectID`
                self.groupedObjects = TrackingEntry.groupEntriesByObjectID(entries: trackingData.map { TrackingEntry.fromTrackingData($0) })
            }
            .alert(isPresented: $showIncompleteAlert) {
                Alert(
                    title: Text("Algunos objetos no están completos"),
                    message: Text("Deseas continuar y enviar los datos de todos modos?"),
                    primaryButton: .default(Text("Continuar")) {
                        enviarDatos()
                    },
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Datos enviados"),
                    message: Text("Los datos se enviaron correctamente."),
                    dismissButton: .default(Text("OK")) {
                        // Resetear estado y navegar de vuelta
                        resetState()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingCameraScannerForLocation) {
            CameraScannerWrapperView(scannedCode: .constant(nil)) { scannedCode in
                // Actualizar la locación en el objeto seleccionado
                if let index = selectedObjectIndex {
                    groupedObjects[index].location = scannedCode
                }
                isShowingCameraScannerForLocation = false
            }
        }
        .sheet(isPresented: $isShowingMaterialEntry) {
            materialEntrySheet
        }
        .sheet(isPresented: $isShowingCameraScannerForMaterial) {
            CameraScannerWrapperView(scannedCode: .constant(nil)) { scannedCode in
                selectedMaterial = scannedCode
                isShowingCameraScannerForMaterial = false
                isShowingMaterialEntry = true
            }
        }
    }
    
    // Vista del encabezado de cada sección
    @ViewBuilder
    func headerView(for group: GroupedObject) -> some View {
        HStack {
            Text("Object ID: \(group.objectID)")
                .font(.headline)
                .foregroundColor(.blue)
            Spacer()
            
            // Mostrar la palomita verde cuando cantidad restante sea 0 y locación esté asignada
            if group.remainingQuantity == 0 && group.location != nil && !group.location!.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    // Vista del contenido de cada sección
    @ViewBuilder
    func contentView(for group: GroupedObject, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Material: \(group.material)")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Locación: \(group.location ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Factura: \(group.bill)")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Cantidad Total: \(group.totalQuantity)")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Cantidad Restante: \(group.remainingQuantity)")
                .font(.subheadline)
                .foregroundColor(group.remainingQuantity == 0 ? .green : .red)
            
            // Mostrar la sublista de materiales agregados
            VStack(alignment: .leading) {
                ForEach(group.subItems, id: \.id) { subItem in
                    HStack {
                        Text("Submaterial: \(subItem.material)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Cantidad: \(subItem.quantity)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer().frame(height: 10)
            
            HStack(spacing: 10) {
                // Botón para escanear y asignar la locación
                Button(action: {
                    selectedObjectIndex = index
                    isShowingCameraScannerForLocation = true
                }) {
                    Label("Asignar Locación", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Botón para agregar material y cantidad
                Button(action: {
                    selectedMaterial = "" // Limpiar campo antes de mostrar la ventana
                    enteredQuantity = "" // Limpiar cantidad antes de mostrar la ventana
                    isShowingMaterialEntry = true // Mostrar la ventana emergente
                    selectedObjectIndex = index // Guardar el índice del objeto
                }) {
                    Label("Agregar Material", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical)
    }
    
    // Botón de Enviar
    var enviarButton: some View {
        Button(action: {
            // Check for incomplete items
            let incompleteObjects = groupedObjects.filter { $0.remainingQuantity != 0 || $0.location == nil || $0.location!.isEmpty }
            
            if !incompleteObjects.isEmpty {
                // Show alert
                showIncompleteAlert = true
            } else {
                // No incomplete items, proceed to send
                enviarDatos()
            }
        }) {
            Text("Enviar")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
/*    // Función para enviar los datos a la API
    func enviarDatos() {
        isLoading = true
        var jsonData: [[String: Any]] = []
        
        // Recorrer todos los `trackingData`
        for tracking in trackingData {
            // Buscar en los `groupedObjects` el objectID correspondiente
            if let group = groupedObjects.first(where: { $0.objectID == tracking.objectID }) {
                if group.remainingQuantity == 0, let location = group.location, !location.isEmpty {
                    // Crear el objeto JSON
                    let jsonObject: [String: Any] = [
                        "TRACKING_NUMBER": tracking.trackingNumber,
                        "OBJECT_ID": tracking.objectID,
                        "INVOICE_NUMBER": tracking.invoiceNumber ?? "",
                        "MATERIAL": tracking.material,
                        "QUANTITY": tracking.quantity,
                        "LOCATION": location,
                        "DELIVERY_TYPE": group.deliveryType ?? "",  // Agregar si es necesario
                        "BILL": "Y"  // Marcar como completado
                    ]
                    jsonData.append(jsonObject)
                }
            }
        }
        */
        // Enviar los datos al API
        sendToAPI(jsonData: jsonData) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    // Mostrar alerta de éxito
                    showSuccessAlert = true
                } else {
                    // Manejar error
                    // Puedes mostrar otra alerta o un mensaje de error
                    print("Error al enviar los datos.")
                }
            }
        }
    }
    
    // Función para enviar los datos a la API con manejo de respuesta
    func sendToAPI(jsonData: [[String: Any]], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/update") else {
            print("URL no válida")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: [])
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error al enviar datos: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código de respuesta HTTP: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        completion(true)
                        return
                    } else {
                        completion(false)
                        return
                    }
                }
                
                completion(false)
                print("Datos enviados correctamente")
            }
            
            task.resume()
        } catch {
            print("Error al serializar JSON: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Vista de ingreso de material
    var materialEntrySheet: some View {
        VStack(spacing: 20) {
            Text("Ingrese Material")
                .font(.headline)
                .foregroundColor(.blue)
            
            TextField("Material", text: $selectedMaterial)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .disableAutocorrection(true)
            
            Button(action: {
                isShowingMaterialEntry = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShowingCameraScannerForMaterial = true
                }
            }) {
                Label("Escanear Material", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            
            TextField("Cantidad", text: $enteredQuantity)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            Button(action: {
                guardarMaterial()
            }) {
                Label("Guardar", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // Función para guardar el material ingresado
    func guardarMaterial() {
        guard let index = selectedObjectIndex else { return }
        
        if groupedObjects.indices.contains(index) {
            var group = groupedObjects[index] // Usar `var` para permitir la mutación
            
            if group.material == selectedMaterial {
                let quantity = Int(enteredQuantity) ?? 0
                if quantity <= group.remainingQuantity {
                    groupedObjects[index].remainingQuantity -= quantity
                    let newSubItem = SubItem(material: selectedMaterial, quantity: quantity)
                    groupedObjects[index].subItems.append(newSubItem)
                } else {
                    print("La cantidad excede la cantidad restante.")
                }
            } else {
                print("El material no coincide.")
            }
        } else {
            print("Índice fuera de rango.")
        }
        
        selectedMaterial = ""
        enteredQuantity = ""
        isShowingMaterialEntry = false
    }
    
    // Función para resetear el estado
    func resetState() {
        // Reagrupar los datos si es necesario, o resetear todos los estados
        self.groupedObjects = TrackingEntry.groupEntriesByObjectID(entries: trackingData.map { TrackingEntry.fromTrackingData($0) })
        selectedObjectIndex = nil
        selectedMaterial = ""
        enteredQuantity = ""
        scannedLocation = nil
        scannedMaterial = nil
    }
}

// Previews
struct MaterialChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [TrackingData] = [
            TrackingData(trackingNumber: "TN001", objectID: 1, invoiceNumber: "INV001", material: "Material A", quantity: "10"),
            TrackingData(trackingNumber: "TN002", objectID: 1, invoiceNumber: "INV001", material: "Material A", quantity: "5"),
            TrackingData(trackingNumber: "TN003", objectID: 2, invoiceNumber: "INV002", material: "Material B", quantity: "20"),
            TrackingData(trackingNumber: "TN004", objectID: 2, invoiceNumber: "INV002", material: "Material B", quantity: "15")
        ]
        
        MaterialChecklistView(trackingData: sampleData)
    }
}
*/

