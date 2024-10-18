import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/ScannerOptionsView.swift", line: 1)
import SwiftUI

struct MaterialChecklistView: View {
    var trackingData: [TrackingData] // Datos de tracking que vienen desde la vista principal
    var objectIDs: [String] // Lista de objectIDs (números)
    
    // Estado para manejar los materiales agregados a cada objectID
    @State private var materialsPerObjectID: [String: [MaterialEntry]] = [:]
    
    // Estado para manejar las ubicaciones asignadas a cada objectID
    @State private var locationsPerObjectID: [String: String] = [:]
    
    // Estado para habilitar el botón de enviar
    @State private var isSendButtonEnabled = false
    
    // Estados para controlar la presentación de sheets y alerts
    @State private var showingAddMaterialSheet = false
    @State private var selectedObjectID: String?
    @State private var newMaterial = ""
    @State private var newQuantityText = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    
    // Estados para la asignación de ubicación
    @State private var showingAssignLocationSheet = false
    @State private var newLocation = ""
    
    // Estado para el escaneo de materiales
    @State private var showingScannerView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: __designTimeInteger("#4051_0", fallback: 20)) {
            Text(__designTimeString("#4051_1", fallback: "Verificación de Materiales"))
                .font(.largeTitle)
                .padding(.top)
            
            // Mostrar lista de objectIDs
            List {
                ForEach(objectIDs, id: \.self) { objectID in
                    Section(header: Text("Object ID: \(objectID)").font(.headline)) {
                        
                        // Mostrar ubicación asignada si existe
                        if let location = locationsPerObjectID[objectID] {
                            HStack {
                                Text(__designTimeString("#4051_2", fallback: "Ubicación Asignada:"))
                                Spacer()
                                Text(location)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // Botón para asignar ubicación
                        Button(action: {
                            selectedObjectID = objectID
                            showingAssignLocationSheet = __designTimeBoolean("#4051_3", fallback: true)
                        }) {
                            Text(locationsPerObjectID[objectID] != nil ? __designTimeString("#4051_4", fallback: "Cambiar Ubicación") : __designTimeString("#4051_5", fallback: "Asignar Ubicación"))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, __designTimeInteger("#4051_6", fallback: 5))
                        
                        // Mostrar materiales agregados a este objectID
                        if let materials = materialsPerObjectID[objectID] {
                            ForEach(materials) { entry in
                                HStack {
                                    Text("Material: \(entry.material)")
                                    Spacer()
                                    Text("Cantidad: \(entry.quantity)")
                                }
                            }
                        }
                        
                        // Botón para agregar material a este objectID
                        Button(action: {
                            selectedObjectID = objectID
                            showingAddMaterialSheet = __designTimeBoolean("#4051_7", fallback: true)
                        }) {
                            Text(__designTimeString("#4051_8", fallback: "Agregar Material"))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, __designTimeInteger("#4051_9", fallback: 5))
                    }
                }
            }
            
            Spacer()
            
            // Botón de Enviar
            Button(action: {
                sendData()
            }) {
                Text(__designTimeString("#4051_10", fallback: "Enviar"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSendButtonEnabled ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(__designTimeInteger("#4051_11", fallback: 10))
            }
            .disabled(!isSendButtonEnabled)
        }
        .padding()
        .navigationTitle(__designTimeString("#4051_12", fallback: "Verificación de Materiales"))
        .onAppear {
            // Aquí puedes inicializar cualquier dato necesario
            checkIfSendButtonShouldBeEnabled()
        }
        .sheet(isPresented: $showingAddMaterialSheet) {
            VStack {
                Text(__designTimeString("#4051_13", fallback: "Agregar Material"))
                    .font(.headline)
                    .padding()
                
                TextField(__designTimeString("#4051_14", fallback: "Material"), text: $newMaterial)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField(__designTimeString("#4051_15", fallback: "Cantidad"), text: $newQuantityText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Botón para escanear material
                Button(action: {
                    showingScannerView = __designTimeBoolean("#4051_16", fallback: true)
                }) {
                    HStack {
                        Image(systemName: __designTimeString("#4051_17", fallback: "camera.viewfinder"))
                        Text(__designTimeString("#4051_18", fallback: "Escanear Material"))
                    }
                }
                .padding()
                
                HStack {
                    Button(__designTimeString("#4051_19", fallback: "Cancelar")) {
                        showingAddMaterialSheet = __designTimeBoolean("#4051_20", fallback: false)
                        newMaterial = __designTimeString("#4051_21", fallback: "")
                        newQuantityText = __designTimeString("#4051_22", fallback: "")
                    }
                    .padding()
                    Spacer()
                    Button(__designTimeString("#4051_23", fallback: "Agregar")) {
                        addMaterial()
                        showingAddMaterialSheet = __designTimeBoolean("#4051_24", fallback: false)
                    }
                    .padding()
                }
            }
            .padding()

        }
        .sheet(isPresented: $showingAssignLocationSheet) {
            VStack {
                Text(__designTimeString("#4051_25", fallback: "Asignar Ubicación"))
                    .font(.headline)
                    .padding()
                
                TextField(__designTimeString("#4051_26", fallback: "Ubicación"), text: $newLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button(__designTimeString("#4051_27", fallback: "Cancelar")) {
                        showingAssignLocationSheet = __designTimeBoolean("#4051_28", fallback: false)
                        newLocation = __designTimeString("#4051_29", fallback: "")
                    }
                    .padding()
                    Spacer()
                    Button(__designTimeString("#4051_30", fallback: "Asignar")) {
                        assignLocation()
                        showingAssignLocationSheet = __designTimeBoolean("#4051_31", fallback: false)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(title: Text(__designTimeString("#4051_32", fallback: "Error")), message: Text(errorMessage), dismissButton: .default(Text(__designTimeString("#4051_33", fallback: "Aceptar"))))
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text(__designTimeString("#4051_34", fallback: "Éxito")), message: Text(__designTimeString("#4051_35", fallback: "Datos enviados correctamente.")), dismissButton: .default(Text(__designTimeString("#4051_36", fallback: "Aceptar"))))
        }
    }
    
    // Resto de tus funciones...
    
    // Función para agregar material
    func addMaterial() {
        guard let objectID = selectedObjectID else { return }
        let material = newMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantityStr = newQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if material.isEmpty || quantityStr.isEmpty {
            showError(message: __designTimeString("#4051_37", fallback: "Por favor, completa todos los campos."))
            return
        }
        
        if let quantity = Int(quantityStr), quantity > __designTimeInteger("#4051_38", fallback: 0) {
            // Agregar el material al objectID
            let entry = MaterialEntry(id: UUID(), material: material, quantity: quantity)
            materialsPerObjectID[objectID, default: []].append(entry)
            
            // Actualizar el estado del botón de enviar
            checkIfSendButtonShouldBeEnabled()
        } else {
            // Mostrar error: cantidad inválida
            showError(message: __designTimeString("#4051_39", fallback: "Cantidad inválida. Por favor, ingresa un número válido."))
        }
        
        // Resetear los campos
        newMaterial = __designTimeString("#4051_40", fallback: "")
        newQuantityText = __designTimeString("#4051_41", fallback: "")
    }
    
    // Función para asignar ubicación
    func assignLocation() {
        guard let objectID = selectedObjectID else { return }
        let location = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if location.isEmpty {
            showError(message: __designTimeString("#4051_42", fallback: "Por favor, ingresa una ubicación."))
            return
        }
        
        // Asignar la ubicación al objectID
        locationsPerObjectID[objectID] = location
        
        // Resetear el campo
        newLocation = __designTimeString("#4051_43", fallback: "")
        
        // Actualizar el estado del botón de enviar
        checkIfSendButtonShouldBeEnabled()
    }
    
    // Función para mostrar un error
    func showError(message: String) {
        errorMessage = message
        showingErrorAlert = __designTimeBoolean("#4051_44", fallback: true)
    }
    
    // Función para verificar si se debe habilitar el botón de enviar
    func checkIfSendButtonShouldBeEnabled() {
        // Habilitar el botón si todos los objectIDs tienen una ubicación asignada y al menos un material agregado
        isSendButtonEnabled = objectIDs.allSatisfy { objectID in
            locationsPerObjectID[objectID] != nil && materialsPerObjectID[objectID]?.isEmpty == __designTimeBoolean("#4051_45", fallback: false)
        }
    }
    
    // Función para enviar los datos
    func sendData() {
        // Aquí implementas la lógica para enviar los datos al servidor o procesarlos como necesites
        // Por ahora, mostraremos una alerta de éxito
        showingSuccessAlert = __designTimeBoolean("#4051_46", fallback: true)
    }
}

// Estructura para representar una entrada de material



// PreviewProvider para visualizar la vista en el canvas de SwiftUI
struct MaterialChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialChecklistView(
            trackingData: [
                TrackingData(externalDeliveryID: __designTimeString("#4051_47", fallback: "1"), material: __designTimeString("#4051_48", fallback: "Material A"), deliveryQty: __designTimeString("#4051_49", fallback: "10"), deliveryNo: __designTimeString("#4051_50", fallback: "D1"), supplierVendor: __designTimeString("#4051_51", fallback: "Vendor X"), supplierName: __designTimeString("#4051_52", fallback: "Supplier X"), container: nil, src: nil),
                TrackingData(externalDeliveryID: __designTimeString("#4051_53", fallback: "2"), material: __designTimeString("#4051_54", fallback: "Material B"), deliveryQty: __designTimeString("#4051_55", fallback: "5"), deliveryNo: __designTimeString("#4051_56", fallback: "D2"), supplierVendor: __designTimeString("#4051_57", fallback: "Vendor Y"), supplierName: __designTimeString("#4051_58", fallback: "Supplier Y"), container: nil, src: nil)
            ],
            objectIDs: [__designTimeString("#4051_59", fallback: "1001"), __designTimeString("#4051_60", fallback: "1002")]
        )
    }
}
