import SwiftUI
import UIKit

// MARK: - Extensión para agregar una cadena a Data
extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

// MARK: - Modelo de material
struct MaterialEntrytool: Identifiable, Codable {
    let id = UUID()
    var material: String
    var uMeasure: String
    var qty: String
    var grossWeight: String
    var netWeight: String
    var details: String
}

// MARK: - Vista para mostrar cada material
struct MaterialRow2: View {
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

// MARK: - Vista principal de InsertToolingView
struct InsertToolingView: View {
    @State private var trackingNo = ""
       @State private var vendor = ""
       @State private var orderNumber = ""
       @State private var date = Date()
       
       // Materiales y fotos
       @State private var materials: [MaterialEntrytool] = []
       @State private var photos: [UIImage] = []
       @State private var showImagePicker = false
       @State private var tempSelectedImage: UIImage?
       
       // Estados de UI
       @State private var isShowingAddMaterialSheet = false
       @State private var isShowingTrackingScanner = false
       @State private var isShowingVendorScanner = false
       @State private var activeAlert: ActiveAlrte3?
       @State private var isLoading = false
       
       // Parámetros de impresión
       @State private var useCustomLabels = true
       @State private var customLabels  = 1
       @State private var showPrintSheet = false
       @State private var objectIDsFromPrint: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado
            VStack {
                Banner() // Define tu vista Banner en tu proyecto
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
                    // Sección Delivery Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery Information")
                            .font(.headline)
                            .foregroundColor(.gray)
                        HStack {
                            CustomTextFieldWithIcon(icon: "doc.text",
                                                    title: "Tracking No",
                                                    text: $trackingNo)
                            Button(action: {
                                isShowingTrackingScanner = true
                                print("DEBUG: Botón de escáner para Tracking No presionado.")
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingTrackingScanner) {
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                                    trackingNo = code
                                    isShowingTrackingScanner = false
                                    print("DEBUG: Código escaneado para Tracking No: \(code)")
                                })
                            }
                        }
                        HStack {
                            CustomTextFieldWithIcon(icon: "person.2.fill",
                                                    title: "Vendor",
                                                    text: $vendor)
                            Button(action: {
                                isShowingVendorScanner = true
                                print("DEBUG: Botón de escáner para Vendor presionado.")
                            }) {
                                Image(systemName: "camera")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .sheet(isPresented: $isShowingVendorScanner) {
                                CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                                    vendor = code
                                    isShowingVendorScanner = false
                                    print("DEBUG: Código escaneado para Vendor: \(code)")
                                })
                            }
                        }
                    }
                    
                    // BOTÓN DE IMPRESIÓN – la única parte que cambia
                                    Button {
                                        showPrintSheet = true
                                    } label: {
                                        Image(systemName: "printer.fill")
                                            .foregroundColor(.green)
                                            .padding()
                                    }
                                    .sheet(isPresented: $showPrintSheet) {
                                        // Cantidad de etiquetas a imprimir
                                        let qty = useCustomLabels ? max(customLabels, 1) : 1
                                        PrintView(
                                            referenceNumber: trackingNo,
                                            trackingData:    [],      // en este flujo no enviamos materiales
                                            customLabels:    qty,     // se pasa como qty
                                            useCustomLabels: true,    // forzamos que use qty
                                            finalObjectIDs:  $objectIDsFromPrint
                                        )
                                    }
                    // Sección Materials
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
                                MaterialRow2(material: mat)
                            }
                        }
                        Button(action: {
                            isShowingAddMaterialSheet = true
                            print("DEBUG: Botón 'Add Material' presionado.")
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
                    
                    // Sección Order Number
                    VStack(alignment: .leading, spacing: 16) {
                        CustomTextFieldWithIcon(icon: "doc.text",
                                                title: "Order Number",
                                                text: $orderNumber)
                    }
                    
                    // Sección Date and Photos
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
                                                print("DEBUG: Eliminada foto en índice: \(index)")
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
                                print("DEBUG: Botón 'Take Photo' presionado.")
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
                    PrintingView(useCustomLabels: $useCustomLabels,
                                          customLabels: $customLabels)
                                 .padding(.horizontal, 20)
                        
                    // Botón Send
                    Button(action: {
                        hideKeyboard()
                        activeAlert = .confirmation
                        print("DEBUG: Botón 'Send' presionado. Se abre alerta de confirmación.")
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
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .confirmation:
                return Alert(
                    title: Text("Are you sure?"),
                    message: Text("Do you want to send this data?"),
                    primaryButton: .destructive(Text("Send")) {
                        print("DEBUG: Confirmación -> Enviando datos.")
                        submitDataMultipart()
                    },
                    secondaryButton: .cancel()
                )
            case .success(let message):
                return Alert(title: Text("Success"), message: Text(message), dismissButton: .default(Text("OK")))
            case .error(let message):
                return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = tempSelectedImage {
                photos.append(image)
                print("DEBUG: Foto añadida. Total fotos: \(photos.count)")
                tempSelectedImage = nil
            }
        }) {
            ImagePicker(sourceType: .camera, selectedImage: $tempSelectedImage)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Función para crear body multipart/form-data
    func createMultipartBody(parameters: [String: String], images: [UIImage], boundary: String) -> Data {
        print("DEBUG: Creando body multipart con \(images.count) imágenes y parámetros: \(parameters)")
        var body = Data()
        let lineBreak = "\r\n"
        // Agregar parámetros
        for (key, value) in parameters {
            body.appendString("--\(boundary)\(lineBreak)")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }
        // Agregar imágenes usando el campo "photos"
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let filename = "photo\(index).jpg"
            print("DEBUG: Agregando imagen \(filename).")
            body.appendString("--\(boundary)\(lineBreak)")
            body.appendString("Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\(lineBreak)")
            body.appendString("Content-Type: image/jpeg\(lineBreak + lineBreak)")
            body.append(imageData)
            body.appendString(lineBreak)
        }
        body.appendString("--\(boundary)--\(lineBreak)")
        return body
    }
    
    // MARK: - Función para enviar datos al endpoint UpdateReceiving
    private func submitDataMultipart() {
        // Validación básica: trackingNo, vendor y al menos un material
        guard !trackingNo.isEmpty, !vendor.isEmpty, !materials.isEmpty else {
            print("DEBUG: Validación falló: trackingNo, vendor o materials vacíos.")
            activeAlert = .error("Please complete all required fields.")
            return
        }
        
        isLoading = true
        
        // Convertir fecha a String con formato "yyyy-MM-dd"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        
        // Serializar materiales a JSON
        var materialsJSON = ""
        do {
            let materialDicts = materials.map { material in
                return [
                    "material": material.material,
                    "uMeasure": material.uMeasure,
                    "qty": material.qty,
                    "grossWeight": material.grossWeight,
                    "netWeight": material.netWeight,
                    "details": material.details
                ]
            }
            let jsonData = try JSONSerialization.data(withJSONObject: materialDicts, options: [])
            materialsJSON = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print("DEBUG: Error al serializar materiales: \(error.localizedDescription)")
            activeAlert = .error("Error processing materials data.")
            isLoading = false
            return
        }
        
        // Parámetros para el servidor
        let parameters: [String: String] = [
            "trackingNo": trackingNo,
            "vendor": vendor,
            "orderNumber": orderNumber,
            "date": dateStr,
            "materials": materialsJSON
        ]
        
        print("DEBUG: Enviando datos con parámetros: \(parameters)")
        let boundary = "Boundary-\(UUID().uuidString)"
        
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/updatereceiving") else {
            print("DEBUG: URL no válida.")
            activeAlert = .error("Invalid API URL.")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let bodyData = createMultipartBody(parameters: parameters, images: photos, boundary: boundary)
        print("DEBUG: Body multipart creado, tamaño: \(bodyData.count) bytes.")
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("DEBUG: Error de red: \(error.localizedDescription)")
                    self.activeAlert = .error("Error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: No se recibió respuesta del servidor.")
                    self.activeAlert = .error("No response from server.")
                    return
                }
                print("DEBUG: Código de estado HTTP: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    print("DEBUG: Solicitud exitosa (200).")
                    self.activeAlert = .success("Datos de recepción actualizados correctamente.")
                    self.clearFields()
                } else {
                    print("DEBUG: El servidor devolvió el status code \(httpResponse.statusCode).")
                    self.activeAlert = .error("Server returned status code \(httpResponse.statusCode).")
                }
            }
        }.resume()
    }
    
    // MARK: - Función para limpiar campos tras envío exitoso
    private func clearFields() {
        print("DEBUG: Limpiando campos tras envío exitoso.")
        trackingNo = ""
        vendor = ""
        orderNumber = ""
        date = Date()
        materials.removeAll()
        photos.removeAll()
    }
}

// MARK: - Sheet para Agregar Material
struct AddMaterialSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var materials: [MaterialEntrytool]
    
    @State private var material = ""
    @State private var uMeasure = ""
    @State private var qty = ""
    @State private var grossWeight = ""
    @State private var netWeight = ""
    @State private var details = ""
    
    @State private var showingMaterialScanner = false
    @State private var showingQtyScanner = false
    @State private var showingGrossScanner = false
    @State private var showingNetScanner = false
    
    let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    CustomTextFieldWithIcon(icon: "barcode.viewfinder",
                                            title: "Material",
                                            text: $material)
                    Button(action: {
                        showingMaterialScanner = true
                        print("DEBUG: Botón de escáner para Material presionado.")
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingMaterialScanner) {
                        CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                            material = code
                            showingMaterialScanner = false
                            print("DEBUG: Código escaneado para Material: \(code)")
                        })
                    }
                }
                CustomTextFieldWithIcon(icon: "ruler",
                                        title: "U Measure",
                                        text: $uMeasure)
                HStack {
                    CustomTextFieldWithIcon(icon: "number",
                                            title: "Quantity",
                                            text: $qty,
                                            keyboardType: .decimalPad)
                    Button(action: {
                        showingQtyScanner = true
                        print("DEBUG: Botón de escáner para Quantity presionado.")
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingQtyScanner) {
                        CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                            if let _ = numberFormatter.number(from: code) {
                                qty = code
                            }
                            showingQtyScanner = false
                            print("DEBUG: Código escaneado para Qty: \(code)")
                        })
                    }
                }
                HStack {
                    CustomTextFieldWithIcon(icon: "scalemass",
                                            title: "Gross Weight",
                                            text: $grossWeight,
                                            keyboardType: .decimalPad)
                    Button(action: {
                        showingGrossScanner = true
                        print("DEBUG: Botón de escáner para Gross Weight presionado.")
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingGrossScanner) {
                        CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                            if let _ = numberFormatter.number(from: code) {
                                grossWeight = code
                            }
                            showingGrossScanner = false
                            print("DEBUG: Código escaneado para Gross Weight: \(code)")
                        })
                    }
                }
                HStack {
                    CustomTextFieldWithIcon(icon: "scalemass.fill",
                                            title: "Net Weight",
                                            text: $netWeight,
                                            keyboardType: .decimalPad)
                    Button(action: {
                        showingNetScanner = true
                        print("DEBUG: Botón de escáner para Net Weight presionado.")
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .sheet(isPresented: $showingNetScanner) {
                        CameraScannerWrapperView(scannedCode: .constant(nil), onCodeScanned: { code in
                            if let _ = numberFormatter.number(from: code) {
                                netWeight = code
                            }
                            showingNetScanner = false
                            print("DEBUG: Código escaneado para Net Weight: \(code)")
                        })
                    }
                }
                CustomTextFieldWithIcon(icon: "info.circle",
                                        title: "Details",
                                        text: $details)
                Button(action: {
                    addMaterial()
                }) {
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
                print("DEBUG: Cancelar AddMaterialSheet.")
            })
        }
    }
    
    private func addMaterial() {
        print("DEBUG: Botón 'Add' presionado en AddMaterialSheet.")
        let newMat = MaterialEntrytool(material: material,
                                       uMeasure: uMeasure,
                                       qty: qty,
                                       grossWeight: grossWeight,
                                       netWeight: netWeight,
                                       details: details)
        materials.append(newMat)
        print("DEBUG: Material agregado: \(newMat.material), total: \(materials.count)")
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

// MARK: - Vistas de apoyo

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

// MARK: - ImagePicker para tomar fotos
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .camera
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        print("DEBUG: ImagePicker inicializado, sourceType: \(sourceType)")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        print("DEBUG: updateUIViewController de ImagePicker llamado.")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
            print("DEBUG: ImagePicker.Coordinator inicializado.")
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("DEBUG: didFinishPickingMediaWithInfo llamado.")
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                print("DEBUG: Imagen seleccionada: \(image.size)")
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("DEBUG: ImagePicker cancelado por el usuario.")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - ActiveAlrte3 para alertas personalizadas
enum ActiveAlrte3: Identifiable {
    case confirmation, success(String), error(String)
    
    var id: String {
        switch self {
        case .confirmation:
            return "confirmation"
        case .success(let msg):
            return "success-\(msg)"
        case .error(let msg):
            return "error-\(msg)"
        }
    }
}

// MARK: - Función para ocultar el teclado
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}



// MARK: - Previews
struct InsertToolingView_Previews: PreviewProvider {
    static var previews: some View {
        InsertToolingView()
    }
}
