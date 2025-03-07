import SwiftUI
import QuickLook

// MARK: - Modelo para FileData
struct FileDataItem: Identifiable, Codable {
    var id: Int
    var fileName: String
    var excelFile: String
    var csvContent: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case fileName = "FileName"
        case excelFile = "ExcelFile"
        case csvContent = "CsvContent"
    }
}

// MARK: - Parser XML para extraer FileData (múltiples elementos)
// (En este ejemplo suponemos que la respuesta de archivos es JSON, pero si fuera XML se podría usar otro parser.)
//
// Si tu API retorna XML, adapta este parser. En este ejemplo usamos JSON para los archivos.
class FileDataParser: NSObject, XMLParserDelegate {
    var currentElement: String = ""
    var files: [FileDataItem] = []
    var currentFile: FileDataItem?

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        // Ignorar el namespace usando hasSuffix
        if elementName.hasSuffix("FileData") {
            currentFile = FileDataItem(id: 0, fileName: "", excelFile: "", csvContent: "")
            print("Inicio de FileData")
        } else if elementName.hasSuffix("ExcelFile") {
            currentElement = "ExcelFile"
            print("Inicio de ExcelFile")
        } else if elementName.hasSuffix("FileName") {
            currentElement = "FileName"
            print("Inicio de FileName")
        } else if elementName.hasSuffix("CsvContent") {
            currentElement = "CsvContent"
            print("Inicio de CsvContent")
        } else if elementName.hasSuffix("ID") {
            currentElement = "ID"
            print("Inicio de ID")
        } else {
            currentElement = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "ExcelFile" {
            currentFile?.excelFile += string
            print("Agregando a ExcelFile: \(string)")
        } else if currentElement == "FileName" {
            currentFile?.fileName += string
            print("Agregando a FileName: \(string)")
        } else if currentElement == "CsvContent" {
            currentFile?.csvContent += string
            print("Agregando a CsvContent: \(string)")
        } else if currentElement == "ID" {
            if let current = currentFile?.id, let intVal = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                currentFile?.id = intVal
            } else {
                currentFile?.id = 0
            }
            print("Agregando a ID: \(string)")
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        print("Finalización del elemento: \(elementName)")
        if elementName.hasSuffix("FileData"), let file = currentFile {
            files.append(file)
            currentFile = nil
        }
        currentElement = ""
    }
}

// MARK: - Modelos para Materiales
struct MaterialData3: Identifiable, Codable {
    // Se genera automáticamente un UUID; no se espera recibirlo en el JSON.
    var id = UUID()
    var Material: String
    var Quantity: String

    enum CodingKeys: String, CodingKey {
        case Material, Quantity
    }
}

struct ExtractMaterialsResponse: Codable {
    let success: Bool
    let data: [MaterialData3]
}

// MARK: - Vista QuickLook para mostrar (opcional) el archivo Excel
struct ExcelPreview: UIViewControllerRepresentable {
    var fileURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        print("Se crea QLPreviewController")
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No se requiere actualización.
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: ExcelPreview
        init(_ parent: ExcelPreview) {
            self.parent = parent
        }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.fileURL as QLPreviewItem
        }
    }
}

// MARK: - Wrapper para UIActivityViewController (Share Sheet)
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: applicationActivities)
        print("Se presenta UIActivityViewController")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

// MARK: - Vista para mostrar y editar la lista de materiales
struct MaterialsListView: View {
    @Binding var materials: [MaterialData3]

    var body: some View {
        Form {
            ForEach($materials) { $material in
                HStack {
                    Text(material.Material)
                        .frame(width: 150, alignment: .leading)
                    TextField("Cantidad", text: $material.Quantity)
                        .keyboardType(.decimalPad)
                }
            }
        }
        .navigationTitle("Materiales")
    }
}

// MARK: - Vista principal: búsqueda de archivos y extracción de materiales
struct ExcelRenderView: View {
    @State private var searchText: String = ""
    @State private var files: [FileDataItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showMaterialsView: Bool = false
    @State private var materials: [MaterialData3] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Campo de búsqueda
                HStack {
                    TextField("Ingrese número de referencia...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    Button("Buscar") {
                        print("Botón 'Buscar' presionado con referencia: \(searchText)")
                        searchExcel(referencia: searchText)
                    }
                }
                .padding()
                
                if isLoading {
                    ProgressView("Cargando...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Mostrar lista de archivos si se encontraron varios
                if !files.isEmpty {
                    if files.count > 1 {
                        List(files) { file in
                            Button(action: {
                                print("Archivo seleccionado: \(file.fileName) con ID: \(file.id)")
                                extractMaterials(for: String(file.id))
                            }) {
                                Text(file.fileName)
                            }
                        }
                    } else if files.count == 1 {
                        // Si solo hay un archivo, se muestra su nombre y se extraen los materiales automáticamente
                        Text("Archivo encontrado: \(files.first!.fileName)")
                            .onAppear {
                                extractMaterials(for: String(files.first!.id))
                            }
                    }
                } else {
                    Spacer()
                    Text("No se ha cargado ningún archivo.")
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                // (Opcional) Vista de previsualización del Excel, si se desea implementarla:
                /*
                if let fileURL = ... {
                    ExcelPreview(fileURL: fileURL)
                        .edgesIgnoringSafeArea(.all)
                }
                */
                
                // NavigationLink para mostrar la vista editable de materiales
                NavigationLink(
                    destination: MaterialsListView(materials: $materials),
                    isActive: $showMaterialsView,
                    label: { EmptyView() }
                )
            }
            .navigationTitle("Búsqueda de Excel")
        }
    }
    
    /// Función que llama al API de archivos y decodifica la respuesta JSON en un arreglo de FileDataItem.
    func searchExcel(referencia: String) {
        print("Iniciando búsqueda para referencia: \(referencia)")
        self.files = []
        self.errorMessage = nil
        self.isLoading = true
        
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/files/\(referencia)") else {
            print("URL inválida")
            self.errorMessage = "URL inválida."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // Cambia a POST si tu API lo requiere.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Realizando solicitud a: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error de red: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                return
            }
            guard let data = data else {
                print("No se recibieron datos")
                DispatchQueue.main.async {
                    self.errorMessage = "No se recibieron datos."
                    self.isLoading = false
                }
                return
            }
            print("Se recibieron \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON de archivos: \(jsonString)")
            }
            
            do {
                let decodedFiles = try JSONDecoder().decode([FileDataItem].self, from: data)
                print("JSON decodificado correctamente. Número de archivos encontrados: \(decodedFiles.count)")
                for file in decodedFiles {
                    print("Archivo: \(file.fileName) - ID: \(file.id)")
                }
                DispatchQueue.main.async {
                    self.files = decodedFiles
                    self.isLoading = false
                    if self.files.count == 1 {
                        self.extractMaterials(for: String(self.files.first!.id))
                    }
                }
            } catch {
                print("Error al decodificar JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error al decodificar la respuesta: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    /// Función que llama al API extractmaterials usando el ID del archivo seleccionado.
    func extractMaterials(for fileID: String) {
        print("Extrayendo materiales para ID: \(fileID)")
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/files/extractmaterials/\(fileID)") else {
            print("URL de extractmaterials inválida")
            DispatchQueue.main.async {
                self.errorMessage = "URL de extractmaterials inválida."
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Realizando solicitud a: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error al extraer materiales: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                print("No se recibieron datos en extractmaterials")
                DispatchQueue.main.async {
                    self.errorMessage = "No se recibieron datos en extractmaterials."
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON de extractmaterials: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let materialsResponse = try decoder.decode(ExtractMaterialsResponse.self, from: data)
                if materialsResponse.success {
                    DispatchQueue.main.async {
                        self.materials = materialsResponse.data
                        self.showMaterialsView = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Extracción fallida."
                    }
                }
            } catch {
                print("Error al decodificar JSON de materiales: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error al decodificar materiales: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct ExcelRenderView_Previews: PreviewProvider {
    static var previews: some View {
        ExcelRenderView()
    }
}
