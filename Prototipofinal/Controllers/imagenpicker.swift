import SwiftUI
import VisionKit
import Vision

struct DocumentCameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var showAlert: Bool
    @Binding var scannedImages: [UIImage]
    @Binding var isDocumentScanning: Bool

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
                        return candidate?.string
                    }

                    recognizedTexts.append(contentsOf: recognizedStrings)
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

                    // Procesar el texto final
                    DispatchQueue.main.async {
                        let fullText = recognizedTexts.joined(separator: "\n")
                        self.parent.recognizedText = fullText

                        // Extraer el material y la cantidad
                        let materials = self.extractMaterials(from: fullText)
                        let quantity = self.extractQuantity(from: fullText)

                        print("Materiales encontrados: \(materials)")
                        print("Cantidad encontrada: \(quantity)")

                        self.parent.recognizedText = "Materiales: \(materials.joined(separator: ", ")), Cantidad: \(quantity)"
                        self.parent.showAlert = true
                        self.parent.isDocumentScanning = false
                    }
                }
            }
        }

        // Método para extraer los materiales según patrones
        func extractMaterials(from text: String) -> [String] {
            let materialPattern = "(SP\\w{1,15}|F03B\\w{1,15}|33\\w{1,15}|16\\w{1,15})"
            var materials = [String]()

            do {
                let regex = try NSRegularExpression(pattern: materialPattern, options: [])
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchedText = String(text[range])
                        materials.append(matchedText)
                    }
                }
            } catch {
                print("Error al crear la expresión regular: \(error.localizedDescription)")
            }

            return materials
        }

        // Método para extraer la cantidad cercana a palabras clave
        func extractQuantity(from text: String) -> String {
            let quantityKeywords = ["QTY", "QUANTITY", "CANTIDAD"]
            let lines = text.components(separatedBy: "\n")
            var quantity: String = ""

            for (index, line) in lines.enumerated() {
                for keyword in quantityKeywords {
                    if line.uppercased().contains(keyword) {
                        // Buscar la línea siguiente o un número cercano
                        if index + 1 < lines.count {
                            let nextLine = lines[index + 1]
                            if let number = extractNumber(from: nextLine) {
                                return number
                            }
                        }

                        // También buscar en la misma línea
                        if let number = extractNumber(from: line) {
                            return number
                        }
                    }
                }
            }

            return quantity
        }

        // Método para extraer el primer número que encuentre en una cadena
        func extractNumber(from text: String) -> String? {
            let numberPattern = "\\d+"
            do {
                let regex = try NSRegularExpression(pattern: numberPattern, options: [])
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

                if let match = matches.first, let range = Range(match.range, in: text) {
                    return String(text[range])
                }
            } catch {
                print("Error al crear la expresión regular: \(error.localizedDescription)")
            }

            return nil
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.parent.isDocumentScanning = false
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                print("Error: \(error.localizedDescription)")
                self.parent.isDocumentScanning = false
            }
        }
    }
}
