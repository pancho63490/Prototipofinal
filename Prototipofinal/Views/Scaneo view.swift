import SwiftUI

struct ScanView: View {
    @State private var shouldNavigateToScan = false
    @State private var shouldNavigateToCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo y Nombre de la App
                VStack {
                    Image(systemName: "camera.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("NixiScan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)

                Spacer()

                // Botón para el Escáner
                Button(action: {
                    shouldNavigateToScan = true
                }) {
                    Text("Escáner")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Botón para la Cámara
                Button(action: {
                    shouldNavigateToCamera = true
                }) {
                    Text("Cámara")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()

                // Navegación a la vista de Escáner
                NavigationLink(destination: BarcodeScannerView(), isActive: $shouldNavigateToScan) {
                    EmptyView()
                }
                
                // Navegación a la vista de Cámara
                NavigationLink(destination: CameraView(), isActive: $shouldNavigateToCamera) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("Escanear")
        }
    }
}



