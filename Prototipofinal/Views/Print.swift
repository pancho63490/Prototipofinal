import SwiftUI

// ────────────────────────── Opciones Reprint / Do Not Reprint
enum ObjectIDOption: String, CaseIterable, Identifiable {
    case reprint    = "Reprint"
    case noReprint  = "Do Not Reprint"
    var id: String { rawValue }
}


struct ObjectIDOptionsSheet: View {
    @Binding var isPresented: Bool
    let completion: (ObjectIDOption) -> Void
    @State private var selected: ObjectIDOption = .reprint
    
    var body: some View {
        Banner()
        NavigationView {
            VStack(spacing: 20) {
                Text("Existing Object IDs Found")
                    .font(.title2).bold().padding(.top)
                
                Text("Object IDs already exist for this REF NUM. What would you like to do?")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Picker("Select an option", selection: $selected) {
                    ForEach(ObjectIDOption.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("Confirm") {
                    isPresented = false
                    completion(selected)
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity).padding()
                .background(Color.blue).foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
            .navigationBarTitle("Options", displayMode: .inline)
        }
    }
}

// ────────────────────────── Vista principal de impresión
struct PrintView: View {
    //‑ Entradas
    var referenceNumber: String
    var trackingData:    [TrackingData]
    var customLabels:    Int
    var useCustomLabels: Bool
    
    //‑ Salida
    @Environment(\.dismiss) private var dismiss
    @Binding var finalObjectIDs: [String]
    
    //‑ Estado
    @State private var objectIDs: [String] = []
    @State private var currentLabel = 1
    @State private var isPrintingComplete = false
    @State private var showOptionSheet = false
    
    enum ActiveAlert: Identifiable {
        case genericError(msg: String, retry: () -> Void, reprint: () -> Void)
        var id: String { UUID().uuidString }
    }
    @State private var alert: ActiveAlert?
    
    // MARK: UI
    var body: some View {
        VStack {
            Text(isPrintingComplete ? "Printing Complete"
                                    : "Printing in Progress")
                .font(.title).bold().padding(.top)
            
            if !isPrintingComplete {
                ProgressView("Printing \(currentLabel)/\(totalLabels()) labels…")
                    .progressViewStyle(.circular)
                    .padding()
            }
            Spacer()
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white,
                                                       Color.blue.opacity(0.1)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear { requestIDs() }
        .onChange(of: isPrintingComplete) { done in
            guard done else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finalObjectIDs = objectIDs
                dismiss()
            }
        }
        .alert(item: $alert) { a in
            switch a {
            case .genericError(let msg, let retry, let reprint):
                return Alert(title: Text("Error"),
                             message: Text(msg),
                             primaryButton: .default(Text("Cancel")) { dismiss() },
                             secondaryButton: .default(Text("Reprint")) { reprint() })
            }
        }
        .sheet(isPresented: $showOptionSheet) {
            ObjectIDOptionsSheet(isPresented: $showOptionSheet) { option in
                option == .reprint ? fetchExistingIDs() : extractExistingIDs()
            }
        }
    }
    
    // MARK: ───────── Cálculos auxiliares
    private func distinctMaterialCount() -> Int {
        Set(trackingData.map(\.material)).count
    }
    private func totalLabels() -> Int {
        if useCustomLabels { return max(customLabels, 1) }
        let c = distinctMaterialCount()
        return c == 0 ? 1 : c
    }
    
    // MARK: ───────── 1 · Solicitar nuevos IDs
    private func requestIDs() {
        let qty = totalLabels()
        let ref = trackingData.first?.grouping ?? referenceNumber
        
        APIServiceobj().requestObjectIDs(requestData: ["QTY": qty, "REF_NUM": ref]) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    guard let ids = resp.objectIDs, !ids.isEmpty else {
                        showErr("No Object IDs received.",
                                retry: requestIDs,
                                reprint: fetchExistingIDs)
                        return
                    }
                    objectIDs = ids.map(String.init)
                    startPrinting()
                    
                case .failure(let err):
                    if shouldShowExistingOption(for: err) {
                        showOptionSheet = true
                    } else {
                        showErr("Error obtaining IDs: \(err.localizedDescription)",
                                retry: requestIDs,
                                reprint: fetchExistingIDs)
                    }
                }
            }
        }
    }
    
    private func shouldShowExistingOption(for error: Error) -> Bool {

        if case APIServiceobj.APIError.objectIDsAlreadyExist = error { return true }
        
        if let urlErr = error as? URLError, urlErr.code == .resourceUnavailable { return true }
       
        let msg = error.localizedDescription.lowercased()
        return msg.contains("already") || msg.contains("has occurred")
    }
    
    // MARK: ───────── 2 · Impresión
    private func startPrinting() { currentLabel = 1; printNext() }
    
    private func printNext() {
        let total = totalLabels()
        guard currentLabel <= total else { isPrintingComplete = true; return }
        guard currentLabel <= objectIDs.count else {
            showErr("Not enough Object IDs.",
                    retry: startPrinting,
                    reprint: fetchExistingIDs)
            return
        }
        
        let id = objectIDs[currentLabel - 1]
        PrintViewController().startPrinting(
            trackingNumber: referenceNumber,
            invoiceNumber:  referenceNumber,
            palletNumber:   currentLabel,
            objectID:       id,
            totalLabels:    total
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    currentLabel += 1
                    printNext()
                } else {
                    showErr(error?.localizedDescription ?? "Print error",
                            retry: { self.printNext() },
                            reprint: fetchExistingIDs)
                }
            }
        }
    }
    
    // MARK: ───────── 3 · Reprint (usar IDs ya existentes)
    private func fetchExistingIDs() {
        APIServiceobj().searchObjectIDs(x: referenceNumber) { res in
            DispatchQueue.main.async {
                switch res {
                case .success(let resp):
                    guard let ids = resp.objectIDs, !ids.isEmpty else {
                        showErr("No existing IDs for this REF NUM.",
                                retry: fetchExistingIDs,
                                reprint: { dismiss() })
                        return
                    }
                    objectIDs = ids.map(String.init)
                    startPrinting()
                    
                case .failure(let err):
                    showErr("Search error: \(err.localizedDescription)",
                            retry: fetchExistingIDs,
                            reprint: { dismiss() })
                }
            }
        }
    }
    
    // MARK: ───────── 4 · Sólo extraer (sin imprimir)
    private func extractExistingIDs() {
        APIServiceobj().searchObjectIDs(x: referenceNumber) { res in
            DispatchQueue.main.async {
                switch res {
                case .success(let resp):
                    finalObjectIDs = resp.objectIDs?.map(String.init) ?? []
                    dismiss()
                case .failure(let err):
                    showErr("Extraction error: \(err.localizedDescription)",
                            retry: extractExistingIDs,
                            reprint: { dismiss() })
                }
            }
        }
    }
    
    // MARK: ───────── Helper Alert
    private func showErr(_ msg: String,
                         retry: @escaping () -> Void,
                         reprint: @escaping () -> Void) {
        alert = .genericError(msg: msg, retry: retry, reprint: reprint)
    }
}
