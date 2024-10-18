import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Views/ManualView.swift", line: 1)
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
        VStack(spacing: __designTimeInteger("#5470_0", fallback: 20)) {
            // Logo y Nombre de la App
            VStack {
                Image(systemName: __designTimeString("#5470_1", fallback: "shippingbox.fill")) // Reemplaza con tu logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: __designTimeInteger("#5470_2", fallback: 50), height: __designTimeInteger("#5470_3", fallback: 50))
                    .foregroundColor(.blue)
                
                Text(__designTimeString("#5470_4", fallback: "NixiScan"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.top, __designTimeInteger("#5470_5", fallback: 20))
            
            ScrollView {
                VStack(spacing: __designTimeInteger("#5470_6", fallback: 20)) {
                    // Información del transportista
                    VStack(alignment: .leading, spacing: __designTimeInteger("#5470_7", fallback: 16)) {
                        Text(__designTimeString("#5470_8", fallback: "Información del Transportista"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Group {
                            CustomTextFieldWithIcon(icon: __designTimeString("#5470_9", fallback: "person.fill"), title: __designTimeString("#5470_10", fallback: "Transportista"), text: $carrierName)
                            CustomTextFieldWithIcon(icon: __designTimeString("#5470_11", fallback: "person"), title: __designTimeString("#5470_12", fallback: "Conductor"), text: $driverName)
                            CustomTextFieldWithIcon(icon: __designTimeString("#5470_13", fallback: "number"), title: __designTimeString("#5470_14", fallback: "Número del Camión"), text: $truckNumber, keyboardType: .numberPad)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: __designTimeInteger("#5470_15", fallback: 16)) {
                        Text(__designTimeString("#5470_16", fallback: "Detalles del Envío"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: __designTimeString("#5470_17", fallback: "tray.and.arrow.down.fill"), title: __designTimeString("#5470_18", fallback: "Número de Inbonds"), text: $numInbonds, keyboardType: .numberPad)
                        
                        HStack(spacing: __designTimeInteger("#5470_19", fallback: 20)) {
                            Toggle(isOn: $isPalletsSelected) {
                                Label(__designTimeString("#5470_20", fallback: "Pallets"), systemImage: __designTimeString("#5470_21", fallback: "cube.box.fill"))
                            }
                            .onChange(of: isPalletsSelected) { value in
                                if value {
                                    isBoxesSelected = __designTimeBoolean("#5470_22", fallback: false)
                                }
                            }
                            
                            Toggle(isOn: $isBoxesSelected) {
                                Label(__designTimeString("#5470_23", fallback: "Cajas"), systemImage: __designTimeString("#5470_24", fallback: "shippingbox.fill"))
                            }
                            .onChange(of: isBoxesSelected) { value in
                                if value {
                                    isPalletsSelected = __designTimeBoolean("#5470_25", fallback: false)
                                }
                            }
                        }
                        
                        // Campo de cantidad que cambia según la opción seleccionada
                        if isPalletsSelected {
                            CustomTextFieldWithIcon(icon: __designTimeString("#5470_26", fallback: "cube.box"), title: __designTimeString("#5470_27", fallback: "Cantidad de Pallets"), text: $palletsQuantity, keyboardType: .numberPad)
                        } else if isBoxesSelected {
                            CustomTextFieldWithIcon(icon: __designTimeString("#5470_28", fallback: "shippingbox"), title: __designTimeString("#5470_29", fallback: "Cantidad de Cajas"), text: $boxesQuantity, keyboardType: .numberPad)
                        }
                    }

                    // Daños en R&D (Opcional)
                    VStack(alignment: .leading, spacing: __designTimeInteger("#5470_30", fallback: 16)) {
                        Text(__designTimeString("#5470_31", fallback: "Daños en R&D (Opcional)"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: __designTimeString("#5470_32", fallback: "cube.box"), title: __designTimeString("#5470_33", fallback: "Pallets Dañados"), text: $damagedPallets, keyboardType: .numberPad)
                        CustomTextFieldWithIcon(icon: __designTimeString("#5470_34", fallback: "shippingbox"), title: __designTimeString("#5470_35", fallback: "Cajas Dañadas"), text: $damagedBoxes, keyboardType: .numberPad)
                    }
                    
                    // Comentarios Adicionales (Opcional)
                    VStack(alignment: .leading, spacing: __designTimeInteger("#5470_36", fallback: 16)) {
                        Text(__designTimeString("#5470_37", fallback: "Comentarios Adicionales (Opcional)"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        CustomTextFieldWithIcon(icon: __designTimeString("#5470_38", fallback: "bubble.left.fill"), title: __designTimeString("#5470_39", fallback: "Comentarios"), text: $additionalComments)
                    }
                    
                    // Fecha y Hora de Llegada
                    VStack(alignment: .leading, spacing: __designTimeInteger("#5470_40", fallback: 16)) {
                        Text(__designTimeString("#5470_41", fallback: "Fecha y Hora de Llegada"))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        DatePicker(__designTimeString("#5470_42", fallback: "Fecha de llegada"), selection: $truckArrivalDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle()) // Estilo compacto
                            .accentColor(.blue) // Color azul para el selector
                    }

                    // Botón de guardar
                    // Botón de guardar
                    Button(action: {
                        // Validar que los campos obligatorios no estén vacíos
                        if carrierName.isEmpty || driverName.isEmpty || truckNumber.isEmpty || numInbonds.isEmpty || (!isPalletsSelected && !isBoxesSelected) {
                            errorMessage = __designTimeString("#5470_43", fallback: "Por favor, completa todos los campos obligatorios.")
                            showAlert = __designTimeBoolean("#5470_44", fallback: true)
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
                                        showAlert = __designTimeBoolean("#5470_45", fallback: true)
                                    }
                                }
                            }
                        }
                    }) {
                        Text(__designTimeString("#5470_46", fallback: "Guardar"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(__designTimeInteger("#5470_47", fallback: 8))
                    }
                    .padding(.top, __designTimeInteger("#5470_48", fallback: 20))
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(__designTimeString("#5470_49", fallback: "Error")), message: Text(errorMessage), dismissButton: .default(Text(__designTimeString("#5470_50", fallback: "OK"))))
                    }

                }
                .padding(.horizontal, __designTimeInteger("#5470_51", fallback: 20))
                .padding(.bottom, __designTimeInteger("#5470_52", fallback: 40))
            }
        }
        .navigationTitle(__designTimeString("#5470_53", fallback: "Ingreso Manual de Datos"))
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
                .padding(.leading, __designTimeInteger("#5470_54", fallback: 10))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(__designTimeInteger("#5470_55", fallback: 8))
    }
}

struct ManualInsertionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualInsertionView()
    }
}
