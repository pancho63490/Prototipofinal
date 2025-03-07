import SwiftUI

struct NewFormView: View {
    @State private var trackingNumber: String = ""
    @State private var carrier: String = ""
    @State private var date: Date = Date()
    @State private var vendor: String = ""
    
    // Almacena las imágenes capturadas y sus representaciones en Base64.
    @State private var capturedImages: [UIImage] = []
    @State private var base64Images: [String] = []
    
    // Controla si se muestra el capturador de cámara.
    @State private var showCameraPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("New Form")
                        .font(.largeTitle)
                        .bold()
                    
                    // Campos del formulario
                    Group {
                        TextField("Tracking Number", text: $trackingNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Carrier", text: $carrier)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        TextField("Vendor", text: $vendor)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Sección de imágenes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Captured Images (max 5)")
                            .font(.headline)
                        
                        if capturedImages.isEmpty {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .overlay(
                                    Text("No images captured")
                                        .foregroundColor(.gray)
                                )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<capturedImages.count, id: \.self) { index in
                                        Image(uiImage: capturedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .clipped()
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        if capturedImages.count < 5 {
                            Button(action: {
                                showCameraPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Capture Image")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        } else {
                            Text("Maximum of 5 images reached")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Botón de envío
                    Button(action: {
                        sendData()
                    }) {
                        Text("Submit Data")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((trackingNumber.isEmpty || carrier.isEmpty || vendor.isEmpty || base64Images.isEmpty) ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(trackingNumber.isEmpty || carrier.isEmpty || vendor.isEmpty || base64Images.isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("New Form")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker { image in
                    if let image = image, capturedImages.count < 5 {
                        capturedImages.append(image)
                        // Si se capturan más de dos imágenes, se utiliza menor calidad (mayor compresión)
                        let quality: CGFloat = capturedImages.count > 2 ? 0.5 : 0.8
                        if let jpegData = image.jpegData(compressionQuality: quality) {
                            let base64String = jpegData.base64EncodedString()
                            base64Images.append(base64String)
                            // Imprime sólo los primeros 50 caracteres y la longitud total para depuración.
                            print("Base64 Preview: \(String(base64String.prefix(50))) (Length: \(base64String.count))")
                        }
                    }
                }
            }
        }
    }
    
    /// Construye el payload JSON y lo envía al API.
    func sendData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        // Depuración: imprime el arreglo completo de imágenes en Base64.
        print("Base64 Images Array: \(base64Images)")
        
        let payload: [String: Any] = [
            "TrackingNumber": trackingNumber,
            "Carrier": carrier,
            "Fecha": dateString,
            "Files": base64Images, // Se envía como arreglo de strings Base64.
            "Vendor": vendor
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Error serializing JSON.")
            return
        }
        
        // Depuración: imprime el JSON que se enviará.
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Payload sent: \(jsonString)")
        }
        
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/postdata") else {
            print("Invalid URL.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                return
            }
            if let data = data, let respString = String(data: data, encoding: .utf8) {
                print("Server response: \(respString)")
            }
        }.resume()
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
            onImagePicked(nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)
            if let uiImage = info[.originalImage] as? UIImage {
                onImagePicked(uiImage)
            } else {
                onImagePicked(nil)
            }
        }
    }
}

struct NewFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewFormView()
    }
}
