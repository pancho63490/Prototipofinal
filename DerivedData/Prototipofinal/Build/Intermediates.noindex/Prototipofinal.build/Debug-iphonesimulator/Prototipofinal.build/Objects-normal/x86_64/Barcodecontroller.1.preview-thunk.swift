import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/frankperez/Desktop/swiftair/Prototipofinal/Prototipofinal/Controllers/Barcodecontroller.swift", line: 1)
import SwiftUI
import AVFoundation

struct CameraScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    var onCodeScanned: ((String) -> Void)?  // Callback opcional para manejar el código escaneado
    let previewLayer = AVCaptureVideoPreviewLayer()
    let captureSession = AVCaptureSession()

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraScannerView
        var captureSession: AVCaptureSession

        init(parent: CameraScannerView, captureSession: AVCaptureSession) {
            self.parent = parent
            self.captureSession = captureSession
        }

        // Se llama cuando se detecta un código
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }

                // Convertir las coordenadas de los metadatos a las de la vista de la cámara
                let transformedMetadataObject = parent.previewLayer.transformedMetadataObject(for: readableObject)

                // Verificar si el código está dentro del recuadro
                if let bounds = transformedMetadataObject?.bounds, parent.isInScanArea(bounds: bounds) {
                    if let stringValue = readableObject.stringValue {
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                        parent.scannedCode = stringValue

                        print("Código detectado: \(stringValue). Deteniendo la sesión de captura.")
                        self.captureSession.stopRunning()

                        // Llamar al callback, si existe
                        if let onCodeScanned = parent.onCodeScanned {
                            onCodeScanned(stringValue)
                        }
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, captureSession: captureSession)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean13, .code128]

            // Definir el área de interés para el escaneo
            let screenSize = UIScreen.main.bounds.size
            let scanRect = CGRect(x: (screenSize.width - __designTimeInteger("#5519_0", fallback: 350)) / __designTimeInteger("#5519_1", fallback: 2), y: (screenSize.height - __designTimeInteger("#5519_2", fallback: 150)) / __designTimeInteger("#5519_3", fallback: 2), width: __designTimeInteger("#5519_4", fallback: 350), height: __designTimeInteger("#5519_5", fallback: 150))
            metadataOutput.rectOfInterest = CGRect(
                x: scanRect.origin.y / screenSize.height,
                y: scanRect.origin.x / screenSize.width,
                width: scanRect.height / screenSize.height,
                height: scanRect.width / screenSize.width
            )
        }

        previewLayer.session = captureSession
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func isInScanArea(bounds: CGRect) -> Bool {
        // Definir el área de escaneo (recuadro verde)
        let scanArea = CGRect(x: UIScreen.main.bounds.midX - __designTimeInteger("#5519_6", fallback: 175), y: UIScreen.main.bounds.midY - __designTimeInteger("#5519_7", fallback: 75), width: __designTimeInteger("#5519_8", fallback: 350), height: __designTimeInteger("#5519_9", fallback: 150))
        return scanArea.contains(bounds)
    }

    func stopSession() {
        print(__designTimeString("#5519_10", fallback: "Deteniendo la sesión de captura manualmente."))
        captureSession.stopRunning()
    }

    func startSession() {
        if !captureSession.isRunning {
            print(__designTimeString("#5519_11", fallback: "Iniciando la sesión de captura manualmente."))
            captureSession.startRunning()
        }
    }
}

struct CameraScannerWrapperView: View {
    @Binding var scannedCode: String?
    @Environment(\.presentationMode) var presentationMode // Para cerrar la vista
    var onCodeScanned: ((String) -> Void)?

    var body: some View {
        ZStack {
            // Camera scanner view
            CameraScannerView(scannedCode: $scannedCode, onCodeScanned: { code in
                scannedCode = code
                if let onCodeScanned = onCodeScanned {
                    onCodeScanned(code)
                }
                self.presentationMode.wrappedValue.dismiss() // Cierra la vista
            })
            .edgesIgnoringSafeArea(.all)

            // Green rectangle for scan area, centered correctly
            Rectangle()
                .stroke(Color.green, lineWidth: __designTimeInteger("#5519_12", fallback: 4))
                .frame(width: __designTimeInteger("#5519_13", fallback: 350), height: __designTimeInteger("#5519_14", fallback: 150))
                .position(
                    x: UIScreen.main.bounds.midX,
                    y: UIScreen.main.bounds.midY - __designTimeInteger("#5519_15", fallback: 75) // Adjust vertically to center
                )

            // Cancel button at the bottom center
            VStack {
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss() // Cierra la vista
                }) {
                    Text(__designTimeString("#5519_16", fallback: "Cancelar"))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(__designTimeFloat("#5519_17", fallback: 0.8)))
                        .cornerRadius(__designTimeInteger("#5519_18", fallback: 8))
                }
                .padding(.bottom, __designTimeInteger("#5519_19", fallback: 50))
            }
        }
    }
}

// Previews
struct CameraScannerWrapperView_Previews: PreviewProvider {
    @State static var scannedCode: String? = nil

    static var previews: some View {
        CameraScannerWrapperView(scannedCode: $scannedCode)
    }
}
