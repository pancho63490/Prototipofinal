import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/Scaneo view.swift", line: 1)
import SwiftUI
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
            VStack(spacing: __designTimeInteger("#2420_0", fallback: 12)) {
                // Encabezado minimalista con logo pequeño y nombre de la aplicación
                VStack {
                    Image(systemName: __designTimeString("#2420_1", fallback: "cube.box.fill"))
                        .resizable()
                        .frame(width: __designTimeInteger("#2420_2", fallback: 40), height: __designTimeInteger("#2420_3", fallback: 40))
                        .foregroundColor(.blue)
                    
                    Text(__designTimeString("#2420_4", fallback: "NixiScan"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.top, __designTimeInteger("#2420_5", fallback: 20))
                
                List {
                    ForEach(groupedObjects.indices, id: \.self) { index in
                        let group = groupedObjects[index]
                        Section(header: headerView(for: group)) {
                            contentView(for: group, index: index)
                        }
                        .background(Color.white)
                        .cornerRadius(__designTimeInteger("#2420_6", fallback: 10))
                    }
                }
                .background(Color.gray.opacity(__designTimeFloat("#2420_7", fallback: 0.1)))
                
                // Botón de Enviar para mandar los datos completados a la API
                enviarButton
                    .padding()
            }
            .background(Color.white)
            .navigationTitle(__designTimeString("#2420_8", fallback: "Listado de Materiales"))
            .onAppear {
                // Agrupar los `trackingData` por `objectID`
                self.groupedObjects = TrackingEntry.groupEntriesByObjectID(entries: trackingData.map { TrackingEntry.fromTrackingData($0) })
            }
            .alert(isPresented: $showIncompleteAlert) {
                Alert(
                    title: Text(__designTimeString("#2420_9", fallback: "Algunos objetos no están completos")),
                    message: Text(__designTimeString("#2420_10", fallback: "Deseas continuar y enviar los datos de todos modos?")),
                    primaryButton: .default(Text(__designTimeString("#2420_11", fallback: "Continuar"))) {
                        enviarDatos()
                    },
                    secondaryButton: .cancel(Text(__designTimeString("#2420_12", fallback: "Cancelar")))
                )
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text(__designTimeString("#2420_13", fallback: "Datos enviados")),
                    message: Text(__designTimeString("#2420_14", fallback: "Los datos se enviaron correctamente.")),
                    dismissButton: .default(Text(__designTimeString("#2420_15", fallback: "OK"))) {
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
                isShowingCameraScannerForLocation = __designTimeBoolean("#2420_16", fallback: false)
            }
        }
        .sheet(isPresented: $isShowingMaterialEntry) {
            materialEntrySheet
        }
        .sheet(isPresented: $isShowingCameraScannerForMaterial) {
            CameraScannerWrapperView(scannedCode: .constant(nil)) { scannedCode in
                selectedMaterial = scannedCode
                isShowingCameraScannerForMaterial = __designTimeBoolean("#2420_17", fallback: false)
                isShowingMaterialEntry = __designTimeBoolean("#2420_18", fallback: true)
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
            if group.remainingQuantity == __designTimeInteger("#2420_19", fallback: 0) && group.location != nil && !group.location!.isEmpty {
                Image(systemName: __designTimeString("#2420_20", fallback: "checkmark.circle.fill"))
                    .foregroundColor(.green)
            }
        }
    }
    
    // Vista del contenido de cada sección
    @ViewBuilder
    func contentView(for group: GroupedObject, index: Int) -> some View {
        VStack(alignment: .leading, spacing: __designTimeInteger("#2420_21", fallback: 8)) {
            Text("Material: \(group.material)")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Locación: \(group.location ?? __designTimeString("#2420_22", fallback: "N/A"))")
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
                .foregroundColor(group.remainingQuantity == __designTimeInteger("#2420_23", fallback: 0) ? .green : .red)
            
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
            
            Spacer().frame(height: __designTimeInteger("#2420_24", fallback: 10))
            
            HStack(spacing: __designTimeInteger("#2420_25", fallback: 10)) {
                // Botón para escanear y asignar la locación
                Button(action: {
                    selectedObjectIndex = index
                    isShowingCameraScannerForLocation = __designTimeBoolean("#2420_26", fallback: true)
                }) {
                    Label(__designTimeString("#2420_27", fallback: "Asignar Locación"), systemImage: __designTimeString("#2420_28", fallback: "location.fill"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(__designTimeFloat("#2420_29", fallback: 0.2)))
                        .foregroundColor(.blue)
                        .cornerRadius(__designTimeInteger("#2420_30", fallback: 10))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Botón para agregar material y cantidad
                Button(action: {
                    selectedMaterial = __designTimeString("#2420_31", fallback: "") // Limpiar campo antes de mostrar la ventana
                    enteredQuantity = __designTimeString("#2420_32", fallback: "") // Limpiar cantidad antes de mostrar la ventana
                    isShowingMaterialEntry = __designTimeBoolean("#2420_33", fallback: true) // Mostrar la ventana emergente
                    selectedObjectIndex = index // Guardar el índice del objeto
                }) {
                    Label(__designTimeString("#2420_34", fallback: "Agregar Material"), systemImage: __designTimeString("#2420_35", fallback: "plus.circle.fill"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(__designTimeFloat("#2420_36", fallback: 0.2)))
                        .foregroundColor(.green)
                        .cornerRadius(__designTimeInteger("#2420_37", fallback: 10))
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
            let incompleteObjects = groupedObjects.filter { $0.remainingQuantity != __designTimeInteger("#2420_38", fallback: 0) || $0.location == nil || $0.location!.isEmpty }
            
            if !incompleteObjects.isEmpty {
                // Show alert
                showIncompleteAlert = __designTimeBoolean("#2420_39", fallback: true)
            } else {
                // No incomplete items, proceed to send
                enviarDatos()
            }
        }) {
            Text(__designTimeString("#2420_40", fallback: "Enviar"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(__designTimeInteger("#2420_41", fallback: 10))
        }
    }
    
    // Función para enviar los datos a la API
    func enviarDatos() {
        isLoading = __designTimeBoolean("#2420_42", fallback: true)
        var jsonData: [[String: Any]] = []
        
        // Recorrer todos los `trackingData`
        for tracking in trackingData {
            // Buscar en los `groupedObjects` el objectID correspondiente
            if let group = groupedObjects.first(where: { $0.objectID == tracking.objectID }) {
                if group.remainingQuantity == __designTimeInteger("#2420_43", fallback: 0), let location = group.location, !location.isEmpty {
                    // Crear el objeto JSON
                    let jsonObject: [String: Any] = [
                        __designTimeString("#2420_44", fallback: "TRACKING_NUMBER"): tracking.trackingNumber,
                        __designTimeString("#2420_45", fallback: "OBJECT_ID"): tracking.objectID,
                        __designTimeString("#2420_46", fallback: "INVOICE_NUMBER"): tracking.invoiceNumber ?? __designTimeString("#2420_47", fallback: ""),
                        __designTimeString("#2420_48", fallback: "MATERIAL"): tracking.material,
                        __designTimeString("#2420_49", fallback: "QUANTITY"): tracking.quantity,
                        __designTimeString("#2420_50", fallback: "LOCATION"): location,
                        __designTimeString("#2420_51", fallback: "DELIVERY_TYPE"): group.deliveryType ?? __designTimeString("#2420_52", fallback: ""),  // Agregar si es necesario
                        __designTimeString("#2420_53", fallback: "BILL"): __designTimeString("#2420_54", fallback: "Y")  // Marcar como completado
                    ]
                    jsonData.append(jsonObject)
                }
            }
        }
        
        // Enviar los datos al API
        sendToAPI(jsonData: jsonData) { success in
            DispatchQueue.main.async {
                isLoading = __designTimeBoolean("#2420_55", fallback: false)
                if success {
                    // Mostrar alerta de éxito
                    showSuccessAlert = __designTimeBoolean("#2420_56", fallback: true)
                } else {
                    // Manejar error
                    // Puedes mostrar otra alerta o un mensaje de error
                    print(__designTimeString("#2420_57", fallback: "Error al enviar los datos."))
                }
            }
        }
    }
    
    // Función para enviar los datos a la API con manejo de respuesta
    func sendToAPI(jsonData: [[String: Any]], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: __designTimeString("#2420_58", fallback: "https://ews-emea.api.bosch.com/Api_XDock/api/update")) else {
            print(__designTimeString("#2420_59", fallback: "URL no válida"))
            completion(__designTimeBoolean("#2420_60", fallback: false))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = __designTimeString("#2420_61", fallback: "PUT")
        request.addValue(__designTimeString("#2420_62", fallback: "application/json"), forHTTPHeaderField: __designTimeString("#2420_63", fallback: "Content-Type"))
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: [])
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error al enviar datos: \(error.localizedDescription)")
                    completion(__designTimeBoolean("#2420_64", fallback: false))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código de respuesta HTTP: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == __designTimeInteger("#2420_65", fallback: 200) {
                        completion(__designTimeBoolean("#2420_66", fallback: true))
                        return
                    } else {
                        completion(__designTimeBoolean("#2420_67", fallback: false))
                        return
                    }
                }
                
                completion(__designTimeBoolean("#2420_68", fallback: false))
                print(__designTimeString("#2420_69", fallback: "Datos enviados correctamente"))
            }
            
            task.resume()
        } catch {
            print("Error al serializar JSON: \(error.localizedDescription)")
            completion(__designTimeBoolean("#2420_70", fallback: false))
        }
    }
    
    // Vista de ingreso de material
    var materialEntrySheet: some View {
        VStack(spacing: __designTimeInteger("#2420_71", fallback: 20)) {
            Text(__designTimeString("#2420_72", fallback: "Ingrese Material"))
                .font(.headline)
                .foregroundColor(.blue)
            
            TextField(__designTimeString("#2420_73", fallback: "Material"), text: $selectedMaterial)
                .padding()
                .background(Color.gray.opacity(__designTimeFloat("#2420_74", fallback: 0.2)))
                .cornerRadius(__designTimeInteger("#2420_75", fallback: 8))
                .disableAutocorrection(__designTimeBoolean("#2420_76", fallback: true))
            
            Button(action: {
                isShowingMaterialEntry = __designTimeBoolean("#2420_77", fallback: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + __designTimeFloat("#2420_78", fallback: 0.5)) {
                    isShowingCameraScannerForMaterial = __designTimeBoolean("#2420_79", fallback: true)
                }
            }) {
                Label(__designTimeString("#2420_80", fallback: "Escanear Material"), systemImage: __designTimeString("#2420_81", fallback: "qrcode.viewfinder"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(__designTimeFloat("#2420_82", fallback: 0.3)))
                    .foregroundColor(.blue)
                    .cornerRadius(__designTimeInteger("#2420_83", fallback: 10))
            }
            
            TextField(__designTimeString("#2420_84", fallback: "Cantidad"), text: $enteredQuantity)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(__designTimeFloat("#2420_85", fallback: 0.2)))
                .cornerRadius(__designTimeInteger("#2420_86", fallback: 8))
            
            Button(action: {
                guardarMaterial()
            }) {
                Label(__designTimeString("#2420_87", fallback: "Guardar"), systemImage: __designTimeString("#2420_88", fallback: "checkmark.circle.fill"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(__designTimeInteger("#2420_89", fallback: 10))
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
                let quantity = Int(enteredQuantity) ?? __designTimeInteger("#2420_90", fallback: 0)
                if quantity <= group.remainingQuantity {
                    groupedObjects[index].remainingQuantity -= quantity
                    let newSubItem = SubItem(material: selectedMaterial, quantity: quantity)
                    groupedObjects[index].subItems.append(newSubItem)
                } else {
                    print(__designTimeString("#2420_91", fallback: "La cantidad excede la cantidad restante."))
                }
            } else {
                print(__designTimeString("#2420_92", fallback: "El material no coincide."))
            }
        } else {
            print(__designTimeString("#2420_93", fallback: "Índice fuera de rango."))
        }
        
        selectedMaterial = __designTimeString("#2420_94", fallback: "")
        enteredQuantity = __designTimeString("#2420_95", fallback: "")
        isShowingMaterialEntry = __designTimeBoolean("#2420_96", fallback: false)
    }
    
    // Función para resetear el estado
    func resetState() {
        // Reagrupar los datos si es necesario, o resetear todos los estados
        self.groupedObjects = TrackingEntry.groupEntriesByObjectID(entries: trackingData.map { TrackingEntry.fromTrackingData($0) })
        selectedObjectIndex = nil
        selectedMaterial = __designTimeString("#2420_97", fallback: "")
        enteredQuantity = __designTimeString("#2420_98", fallback: "")
        scannedLocation = nil
        scannedMaterial = nil
    }
}

// Previews
struct MaterialChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [TrackingData] = [
            TrackingData(trackingNumber: __designTimeString("#2420_99", fallback: "TN001"), objectID: __designTimeInteger("#2420_100", fallback: 1), invoiceNumber: __designTimeString("#2420_101", fallback: "INV001"), material: __designTimeString("#2420_102", fallback: "Material A"), quantity: __designTimeString("#2420_103", fallback: "10")),
            TrackingData(trackingNumber: __designTimeString("#2420_104", fallback: "TN002"), objectID: __designTimeInteger("#2420_105", fallback: 1), invoiceNumber: __designTimeString("#2420_106", fallback: "INV001"), material: __designTimeString("#2420_107", fallback: "Material A"), quantity: __designTimeString("#2420_108", fallback: "5")),
            TrackingData(trackingNumber: __designTimeString("#2420_109", fallback: "TN003"), objectID: __designTimeInteger("#2420_110", fallback: 2), invoiceNumber: __designTimeString("#2420_111", fallback: "INV002"), material: __designTimeString("#2420_112", fallback: "Material B"), quantity: __designTimeString("#2420_113", fallback: "20")),
            TrackingData(trackingNumber: __designTimeString("#2420_114", fallback: "TN004"), objectID: __designTimeInteger("#2420_115", fallback: 2), invoiceNumber: __designTimeString("#2420_116", fallback: "INV002"), material: __designTimeString("#2420_117", fallback: "Material B"), quantity: __designTimeString("#2420_118", fallback: "15"))
        ]
        
        MaterialChecklistView(trackingData: sampleData)
    }
}
