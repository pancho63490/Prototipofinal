import SwiftUI

struct ManualInsertionView: View {
    @State private var carrierName = ""
    @State private var driverName = ""
    @State private var truckNumber = "" // Campo obligatorio
    @State private var numInbonds = "" // Campo obligatorio
    @State private var palletsQuantity = ""
    @State private var boxesQuantity = ""

    @State private var isPalletsSelected = false // Obligatorio seleccionar una opción
    @State private var isBoxesSelected = false // Obligatorio seleccionar una opción
    
    @State private var damagedPallets = ""
    @State private var damagedBoxes = ""
    @State private var additionalComments = ""
    @State private var truckArrivalDate = Date()

    @State private var showAlert = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // Logo y Nombre de la App
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
                    // Información del transportista
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Información del Transportista")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Group {
                            CustomTextFieldWithIcon(icon: "person.fill", title: "Transportista", text: $carrierName)
                            CustomTextFieldWithIcon(icon: "person", title: "Conductor", text: $driverName)
                            CustomTextFieldWithIcon(icon: "number", title: "Número del Camión", text: $truckNumber, keyboardType: .numberPad)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detalles del Envío")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "tray.and.arrow.down.fill", title: "Número de Inbonds", text: $numInbonds, keyboardType: .numberPad)
                        
                        HStack(spacing: 20) {
                            Toggle(isOn: $isPalletsSelected) {
                                Label("Pallets", systemImage: "cube.box.fill")
                            }
                            .onChange(of: isPalletsSelected) { value in
                                if value {
                                    isBoxesSelected = false
                                }
                            }
                            
                            Toggle(isOn: $isBoxesSelected) {
                                Label("Cajas", systemImage: "shippingbox.fill")
                            }
                            .onChange(of: isBoxesSelected) { value in
                                if value {
                                    isPalletsSelected = false
                                }
                            }
                        }
                        
                        // Campo de cantidad que cambia según la opción seleccionada
                        if isPalletsSelected {
                            CustomTextFieldWithIcon(icon: "cube.box", title: "Cantidad de Pallets", text: $palletsQuantity, keyboardType: .numberPad)
                        } else if isBoxesSelected {
                            CustomTextFieldWithIcon(icon: "shippingbox", title: "Cantidad de Cajas", text: $boxesQuantity, keyboardType: .numberPad)
                        }
                    }

                    // Daños en R&D (Opcional)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daños en R&D (Opcional)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "cube.box", title: "Pallets Dañados", text: $damagedPallets, keyboardType: .numberPad)
                        CustomTextFieldWithIcon(icon: "shippingbox", title: "Cajas Dañadas", text: $damagedBoxes, keyboardType: .numberPad)
                    }
                    
                    // Comentarios Adicionales (Opcional)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comentarios Adicionales (Opcional)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: "bubble.left.fill", title: "Comentarios", text: $additionalComments)
                    }
                    
                    // Fecha y Hora de Llegada
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fecha y Hora de Llegada")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        DatePicker("Fecha de llegada", selection: $truckArrivalDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle()) // Estilo compacto
                            .accentColor(.blue) // Color azul para el selector
                    }

                    // Botón de guardar
                    // Botón de guardar
                    Button(action: {
                        // Validar que los campos obligatorios no estén vacíos
                        if carrierName.isEmpty || driverName.isEmpty || truckNumber.isEmpty || numInbonds.isEmpty || (!isPalletsSelected && !isBoxesSelected) {
                            errorMessage = "Por favor, completa todos los campos obligatorios."
                            showAlert = true
                        } else {
                            // Crear el objeto ShipmentData
                            let shipmentData = ShipmentData(
                                carrierName: carrierName,
                                driverName: driverName,
                                truckNumber: truckNumber,
                                numInbonds: numInbonds,
                                palletsQuantity: isPalletsSelected ? palletsQuantity : nil,
                                boxesQuantity: isBoxesSelected ? boxesQuantity : nil,
                                damagedPallets: damagedPallets,
                                damagedBoxes: damagedBoxes,
                                additionalComments: additionalComments,
                                truckArrivalDate: truckArrivalDate
                            )
                            
                            // Enviar los datos a la API
                            APIServicioManual().sendShipmentData(shipmentData) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let message):
                                        print(message)
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                        showAlert = true
                                    }
                                }
                            }
                        }
                    }) {
                        Text("Guardar")
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

struct ManualInsertionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualInsertionView()
    }
}
