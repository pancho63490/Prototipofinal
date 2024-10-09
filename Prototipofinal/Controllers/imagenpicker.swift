import SwiftUI
import VisionKit
import Vision

struct DocumentCameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var showAlert: Bool
    @Binding var scannedImages: [UIImage]
    @Binding var isDocumentScanning: Bool // Vinculación para controlar si el escáner está activo

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentCameraView

        init(_ parent: DocumentCameraView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true) {
                self.parent.scannedImages = []
                var recognizedTexts = [String]()

                // Configurar el reconocimiento de texto
                let textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

                    let recognizedStrings = observations.compactMap { observation in
                        let candidate = observation.topCandidates(1).first
                        return candidate?.confidence ?? 0 >= 0.8 ? candidate?.string : nil
                    }

                    recognizedTexts.append(recognizedStrings.joined(separator: "\n"))
                }

                textRecognitionRequest.recognitionLevel = .accurate
                textRecognitionRequest.usesLanguageCorrection = true

                // Procesar cada página escaneada
                DispatchQueue.global(qos: .userInitiated).async {
                    for pageIndex in 0..<scan.pageCount {
                        let image = scan.imageOfPage(at: pageIndex)
                        self.parent.scannedImages.append(image)

                        guard let cgImage = image.cgImage else { continue }
                        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                        do {
                            try requestHandler.perform([textRecognitionRequest])
                        } catch {
                            print("Error en el reconocimiento de texto: \(error.localizedDescription)")
                        }
                    }

                    // Mostrar el texto reconocido en el hilo principal
                    DispatchQueue.main.async {
                        self.parent.recognizedText = recognizedTexts.joined(separator: "\n")
                        self.parent.showAlert = true
                        self.parent.isDocumentScanning = false // Cerrar el escáner
                    }
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                // Volver al ContentView actualizando el estado
                self.parent.isDocumentScanning = false
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                print("Error: \(error.localizedDescription)")
                // Asegurarse de cerrar la vista en caso de error
                self.parent.isDocumentScanning = false
            }
        }
    }
}
