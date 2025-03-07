import SwiftUI
import UIKit

// MARK: - Modelo de material (cada uno con sus campos)
struct MaterialEntrytool: Identifiable {
    let id = UUID()
    var material: String
    var uMeasure: String
    var qty: String
    var grossWeight: String
    var netWeight: String
    var details: String
}

// MARK: - Vista para mostrar cada material de forma detallada y atractiva
struct MaterialRow: View {
    var material: MaterialEntrytool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(material.material)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(material.uMeasure)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Campo de detalles (si no está vacío)
            if !material.details.isEmpty {
                Text(material.details)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Label("Qty: \(material.qty)", systemImage: "number")
                    .font(.caption)
                Spacer()
                Label("Gross: \(material.grossWeight)", systemImage: "scalemass")
                    .font(.caption)
                Spacer()
                Label("Net: \(material.netWeight)", systemImage: "scalemass.fill")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Vista principal (estilo ManualInsertionView)
struct InsertToolingView: View {
    // Campos principales
    @State private var trackingNo = ""
    @State private var vendor = ""
    @State private var orderNumber = ""
    @State private var date = Date()
    
    // Lista de materiales
    @State private var materials: [MaterialEntrytool] = []
    
    // Fotos (máximo 3)
    @State private var photos: [UIImage] = []
    @State private var showImagePicker = false
    @State private var tempSelectedImage: UIImage? = nil
    
    // Flag para abrir sheet de “Agregar Material”
    @State private var isShowingAddMaterialSheet = false
    
    // Para manejar alertas y estado de carga
    @State private var activeAlert: ActiveAlertType? = nil
    @State private var isLoading = false
    
    // Para simular escáner en Tracking No o Vendor (si deseas)
    @State private var isShowingTrackingScanner = false
    @State private var isShowingVendorScanner = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado (logo + título)
            VStack {
                Image(systemName: "shippingbox.fill")
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
                    
                    // MARK: - Sección: Delivery Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery Information")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Tracking No + Botón de Escáner (opcional)
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "doc.text",
                                title: "Tracking No",
                                text: $trackingNo
                            )
                            
                            Button(action: {
                                isShowingTrackingScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingTrackingScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { code in
                                        trackingNo = code
                                        isShowingTrackingScanner = false
                                    }
                                )
                            }
                        }
                        
                        // Vendor + Botón de Escáner (opcional)
                        HStack {
                            CustomTextFieldWithIcon(
                                icon: "person.2.fill",
                                title: "Vendor",
                                text: $vendor
                            )
                            
                            Button(action: {
                                isShowingVendorScanner = true
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingVendorScanner) {
                                CameraScannerWrapperView(
                                    scannedCode: .constant(nil),
                                    onCodeScanned: { code in
                                        vendor = code
                                        isShowingVendorScanner = false
                                    }
                                )
                            }
                        }
                    }
                    
                    // MARK: - Sección: Materials List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Materials")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if materials.isEmpty {
                            Text("No materials added yet.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(materials) { mat in
                                MaterialRow(material: mat)
                            }
                        }
                        
                        // Botón para agregar material
                        Button(action: {
                            isShowingAddMaterialSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Material")
                            }
                        }
                        .sheet(isPresented: $isShowingAddMaterialSheet) {
                            AddMaterialSheet(materials: $materials)
                        }
                    }
                    
                    // Sección: Order Number (opcional)
                    VStack(alignment: .leading, spacing: 16) {
                        CustomTextFieldWithIcon(
                            icon: "doc.text",
                            title: "Order Number",
                            text: $orderNumber
                        )
                    }
                    
                    // MARK: - Sección: Date and Photos
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Date and Photos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        if !photos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(photos.indices, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: photos[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipped()
                                                .cornerRadius(8)
                                            
                                            Button(action: {
                                                photos.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .imageScale(.large)
                                                    .foregroundColor(.red)
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        } else {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                                    .foregroundColor(.gray)
                                Text("No photos yet")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                            .padding(.vertical, 5)
                        }
                        
                        Button(action: {
                            if photos.count < 3 {
                                showImagePicker = true
                            }
                        }) {
                            Text(photos.count < 3 ? "Take Photo" : "Maximum 3 Photos")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(photos.count < 3 ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(photos.count >= 3)
                    }
                    
                    // MARK: - Botón “Send”
                    Button(action: {
                        hideKeyboard()
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
                    
                    if isLoading {
                        ProgressView("Sending data...")
                            .padding()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Insert Tooling")
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .confirmation:
                return Alert(
                    title: Text("Are you sure?"),
                    message: Text("Do you want to send this data?"),
                    primaryButton: .destructive(Text("Send")) {
                        submitData()
                    },
                    secondaryButton: .cancel()
                )
            case .success(let message):
                return Alert(
                    title: Text("Success"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = tempSelectedImage {
                photos.append(image)
                tempSelectedImage = nil
            }
        }) {
            ImagePicker(sourceType: .camera, selectedImage: $tempSelectedImage)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Funciones
    
    /// Envía la información al endpoint de Bosch
    private func submitData() {
        // Validación básica antes de enviar
        if trackingNo.isEmpty || vendor.isEmpty || materials.isEmpty {
            activeAlert = .error("Please complete all required fields.")
            return
        }
        
        isLoading = true
        
        // 1) Generar el JSON que se va a enviar
        let jsonString = generateJSON()
        
        // 2) Configurar la URL de tu API
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/updatereceiving") else {
            activeAlert = .error("Invalid API URL.")
            isLoading = false
            return
        }
        
        // 3) Construir el URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Si tu API requiere autenticación con token, descomenta y agrega tu token:
        // request.setValue("Bearer TU_TOKEN_AQUI", forHTTPHeaderField: "Authorization")
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        // 4) Hacer la petición usando URLSession
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Manejo de errores de conexión
                if let error = error {
                    self.activeAlert = .error("Error: \(error.localizedDescription)")
                    return
                }
                
                // Verificación de la respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.activeAlert = .error("No response from server.")
                    return
                }
                
                // Si el status code es 200, consideramos que es un éxito
                if httpResponse.statusCode == 200 {
                    self.activeAlert = .success("Data sent successfully.")
                    // Limpiar campos tras envío exitoso
                    self.clearFields()
                } else {
                    // Manejo de códigos de error
                    self.activeAlert = .error("Server returned status code \(httpResponse.statusCode).")
                }
            }
        }.resume()
    }
    
    private func clearFields() {
        trackingNo = ""
        vendor = ""
        orderNumber = ""
        date = Date()
        materials.removeAll()
        photos.removeAll()
    }
    
    private func generateJSON() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)
        
        let photosBase64 = photos.compactMap {
            $0.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }
        
        let materialsArray: [[String: Any]] = materials.map { mat in
            [
                "material": mat.material,
                "uMeasure": mat.uMeasure,
                "qty": mat.qty,
                "grossWeight": mat.grossWeight,
                "netWeight": mat.netWeight,
                "details": mat.details
            ]
        }
        
        let jsonDict: [String: Any] = [
            "trackingNo": trackingNo,
            "vendor": vendor,
            "orderNumber": orderNumber,
            "date": dateStr,
            "materials": materialsArray,
            "photos": photosBase64
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "Error generating JSON"
    }
}

// MARK: - Sheet para Agregar Material
struct AddMaterialSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var materials: [MaterialEntrytool]
    
    // Campos para nuevo material
    @State private var material = ""
    @State private var uMeasure = ""
    @State private var qty = ""
    @State private var grossWeight = ""
    @State private var netWeight = ""
    @State private var details = ""
    
    // Escáneres en caso de necesitarlos
    @State private var showingMaterialScanner = false
    @State private var showingQtyScanner = false
    @State private var showingGrossScanner = false
    @State private var showingNetScanner = false
    
    // Validador de números
    let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Material + Botón Escáner
                HStack {
                    CustomTextFieldWithIcon(
                        icon: "barcode.viewfinder",
                        title: "Material",
                        text: $material
                    )
                    Button(action: {
                        showingMaterialScanner = true
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingMaterialScanner) {
                        CameraScannerWrapperView(
                            scannedCode: .constant(nil),
                            onCodeScanned: { code in
                                material = code
                                showingMaterialScanner = false
                            }
                        )
                    }
                }
                
                // UMeasure
                CustomTextFieldWithIcon(
                    icon: "ruler",
                    title: "U Measure",
                    text: $uMeasure
                )
                
                // Cantidad + Escáner
                HStack {
                    CustomTextFieldWithIcon(
                        icon: "number",
                        title: "Quantity",
                        text: $qty,
                        keyboardType: .decimalPad
                    )
                    Button(action: {
                        showingQtyScanner = true
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingQtyScanner) {
                        CameraScannerWrapperView(
                            scannedCode: .constant(nil),
                            onCodeScanned: { code in
                                if let _ = numberFormatter.number(from: code) {
                                    qty = code
                                }
                                showingQtyScanner = false
                            }
                        )
                    }
                }
                
                // Gross Weight + Escáner
                HStack {
                    CustomTextFieldWithIcon(
                        icon: "scalemass",
                        title: "Gross Weight",
                        text: $grossWeight,
                        keyboardType: .decimalPad
                    )
                    Button(action: {
                        showingGrossScanner = true
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingGrossScanner) {
                        CameraScannerWrapperView(
                            scannedCode: .constant(nil),
                            onCodeScanned: { code in
                                if let _ = numberFormatter.number(from: code) {
                                    grossWeight = code
                                }
                                showingGrossScanner = false
                            }
                        )
                    }
                }
                
                // Net Weight + Escáner
                HStack {
                    CustomTextFieldWithIcon(
                        icon: "scalemass.fill",
                        title: "Net Weight",
                        text: $netWeight,
                        keyboardType: .decimalPad
                    )
                    Button(action: {
                        showingNetScanner = true
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingNetScanner) {
                        CameraScannerWrapperView(
                            scannedCode: .constant(nil),
                            onCodeScanned: { code in
                                if let _ = numberFormatter.number(from: code) {
                                    netWeight = code
                                }
                                showingNetScanner = false
                            }
                        )
                    }
                }
                
                // Nuevo campo: Details
                CustomTextFieldWithIcon(
                    icon: "info.circle",
                    title: "Details",
                    text: $details
                )
                
                // Botón "Add"
                Button(action: addMaterial) {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(camposInvalidos() ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(camposInvalidos())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Material")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func addMaterial() {
        let newMat = MaterialEntrytool(
            material: material,
            uMeasure: uMeasure,
            qty: qty,
            grossWeight: grossWeight,
            netWeight: netWeight,
            details: details
        )
        materials.append(newMat)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func camposInvalidos() -> Bool {
        if material.isEmpty || uMeasure.isEmpty || qty.isEmpty ||
           grossWeight.isEmpty || netWeight.isEmpty || details.isEmpty {
            return true
        }
        if numberFormatter.number(from: qty) == nil ||
           numberFormatter.number(from: grossWeight) == nil ||
           numberFormatter.number(from: netWeight) == nil {
            return true
        }
        return false
    }
}

// MARK: - Vistas de ayuda (escáner, textfields, etc.)

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

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct InsertToolingView_Previews: PreviewProvider {
    static var previews: some View {
        InsertToolingView()
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}

// MARK: - ImagePicker para tomar fotos
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .camera
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
