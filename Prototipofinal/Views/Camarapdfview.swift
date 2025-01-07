import SwiftUI
import VisionKit
import Vision

struct CameraView: View {
    @State private var recognizedText: String = ""
    @State private var showAlert: Bool = false
    @State private var scannedImages: [UIImage] = [] // Almacena las imágenes escaneadas
    @State private var showDocumentCamera = false
    @State private var isDocumentScanning = false 

    var body: some View {
        VStack {
            Text("XDOCK - Cámara")
                .font(.largeTitle)
                .padding()

            if !scannedImages.isEmpty {
                TabView {
                    ForEach(scannedImages, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .padding()
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 300)
            } else {
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding()
            }

            Button(action: {
                showDocumentCamera = true
            }) {
                Text("Abrir Cámara")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $showDocumentCamera) {
                DocumentCameraView(recognizedText: $recognizedText, showAlert: $showAlert, scannedImages: $scannedImages, isDocumentScanning: $isDocumentScanning)
            }

            Spacer()

            if showAlert {
                Text("Texto Reconocido:")
                    .font(.headline)
                    .padding(.top)
                ScrollView {
                    Text(recognizedText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
    }
}
