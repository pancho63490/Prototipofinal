import SwiftUI

struct ManualInsertionView: View {
    // Variables de estado para Invoice y Reference Number
    @State private var invoiceNumber = ""
    @State private var referenceNumber = ""
    
    // Variables de estado para Truck y Provider Reference
    @State private var truckReference = ""
    @State private var providerReference = ""
    
    // Lista de materiales
    @State private var materials: [Material] = []
    @State private var showingAddMaterialSheet = false
    
    // Variables para alertas y mensajes de error
    @State private var showAlert = false
    @State private var errorMessage = ""
    
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
                    // Información de la Factura y Referencia
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Información de la Factura")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "doc.text", title: "Número de Factura o numero de referencia", text: $invoiceNumber)
                        
                  
                    }
                    
                    // Referencia del Camión y Proveedor
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Referencia del Transporte")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "number", title: "Referencia del Camión o proveedor ", text: $truckReference)
                        
                     
                    }
                    
                    // Sección de Materiales
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lista de Materiales")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Lista de materiales agregados
                        ForEach(materials) { material in
                            HStack {
                                Text("Código: \(material.code)")
                                Spacer()
                                Text("Cantidad: \(material.quantity)")
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
                        // Validación de campos obligatorios
                        if invoiceNumber.isEmpty ||
                            referenceNumber.isEmpty ||
                            truckReference.isEmpty ||
                            providerReference.isEmpty ||
                            materials.isEmpty {
                            errorMessage = "Por favor, completa todos los campos obligatorios."
                            showAlert = true
                        } else {
                            // Aquí puedes implementar la lógica para enviar los datos a tu API
                            print("Datos enviados exitosamente")
                        }
                    }) {
                        Text("Enviar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Ingreso Manual de Datos")
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
                        if let _ = numberFormatter.number(from: quantity) {
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
    
    // Asegúrate de tener tu CameraScannerView implementado en otro lugar
    // struct CameraScannerView: UIViewControllerRepresentable { ... }
    
    struct ManualInsertionView_Previews: PreviewProvider {
        static var previews: some View {
            ManualInsertionView()
        }
    }
}
