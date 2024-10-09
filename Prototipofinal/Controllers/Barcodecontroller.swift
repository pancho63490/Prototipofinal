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
            let scanRect = CGRect(x: (screenSize.width - 350) / 2, y: (screenSize.height - 150) / 2, width: 350, height: 150)
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
        let scanArea = CGRect(x: UIScreen.main.bounds.midX - 175, y: UIScreen.main.bounds.midY - 75, width: 350, height: 150)
        return scanArea.contains(bounds)
    }

    func stopSession() {
        print("Deteniendo la sesión de captura manualmente.")
        captureSession.stopRunning()
    }

    func startSession() {
        if !captureSession.isRunning {
            print("Iniciando la sesión de captura manualmente.")
            captureSession.startRunning()
        }
    }
}
