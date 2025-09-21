import SwiftUI
import Foundation

// ──────────────────────────────── Modelos ────────────────────────────────

// Versión mínima solo para esta pantalla
struct TrackingData3 {
    let material:  String
    let grouping:  String
    let quantity:  Int
    let status:    String
    let timestamp: Date
}

extension TrackingData {
    init(from t: TrackingData3) {
        self.externalDeliveryID = ""
        self.material  = t.material
        self.deliveryQty = "\(t.quantity)"
        self.deliveryNo  = ""
        self.supplierVendor = ""
        self.supplierName   = ""
        self.container = nil
        self.src       = nil
        self.unit      = ""
        self.pesoBruto = nil
        self.pesoNeto  = nil
        self.grouping  = t.grouping
    }
}

// ──────────────────────────────── API & Helpers ────────────────────────────────

struct ApiResponse: Codable {
    let Success: Bool
    let Data: [ReferenceData]
}

struct ReferenceData: Codable, Identifiable {
    let ReferenceNumber: String
    let ObjectIds: [Int]
    var id: String { ReferenceNumber }
    var objectCount: Int { ObjectIds.count }
}

// ──────────────────────────────── Vista principal ────────────────────────────────

struct ReprintObView: View {
    
    // Carga
    @State private var references: [ReferenceData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Navegación / impresión
    @State private var selectedReferenceNumber = ""
    @State private var shouldNavigateToPrint = false
    @State private var objectIDsFromPrint: [String] = []
    
    // Datos para PrintView
    @State private var trackingData3: [TrackingData3] = []
    @State private var customLabels = 0
    @State private var useCustomLabels = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Cargando datos…")
                    } else if let msg = errorMessage {
                        ErrorView(message: msg) { Task { await fetchData() } }
                    } else if references.isEmpty {
                        EmptyStateView()
                    } else {
                        referenceListView
                    }
                }
            }
            .navigationTitle("Reprint OB")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) { Image(systemName: "arrow.clockwise") }
                }
            }
            .task { await fetchData() }
        }
    }
    
    // ───────── Lista
    private var referenceListView: some View {
        List {
            ForEach(references) { ref in
                Button { prepareForPrinting(reference: ref) } label: {
                    ReferenceRow(reference: ref)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .background(
            NavigationLink(
                destination: PrintView(
                    referenceNumber: selectedReferenceNumber,
                    trackingData:    trackingData3.map(TrackingData.init(from:)), // conversión aquí
                    customLabels:    customLabels,
                    useCustomLabels: useCustomLabels,
                    finalObjectIDs:  $objectIDsFromPrint
                ),
                isActive: $shouldNavigateToPrint
            ) { EmptyView() }
            .hidden()
        )
    }
    
    // ───────── Preparar datos y navegar
    private func prepareForPrinting(reference: ReferenceData) {
        selectedReferenceNumber = reference.ReferenceNumber
        customLabels            = reference.ObjectIds.count
        useCustomLabels         = true
        
        trackingData3 = [
            TrackingData3(
                material:  "REPRINT_OB",
                grouping:  reference.ReferenceNumber,
                quantity:  reference.ObjectIds.count,
                status:    "Pending",
                timestamp: Date()
            )
        ]
        objectIDsFromPrint = reference.ObjectIds.map(String.init)
        shouldNavigateToPrint = true
    }
    
    // ───────── Networking
    private func fetchData() async {
        isLoading = true; defer { isLoading = false }
        errorMessage = nil
        
        do {
            let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/getinformation")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ApiResponse.self, from: data)
            references  = decoded.Success ? decoded.Data : []
            if references.isEmpty { errorMessage = "No se encontraron referencias" }
        } catch {
            errorMessage = "Error al cargar datos: \(error.localizedDescription)"
        }
    }
    private func refreshData() { Task { await fetchData() } }
}

// ──────────────────────────────── Sub‑vistas ────────────────────────────────

struct ReferenceRow: View {
    let reference: ReferenceData
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "number.circle.fill")
                .font(.title2).foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(reference.ReferenceNumber).font(.headline)
                Text("\(reference.objectCount) objetos")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48)).foregroundColor(.secondary)
            Text("No hay referencias disponibles")
                .font(.headline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView2: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48)).foregroundColor(.red)
            Text(message).multilineTextAlignment(.center).padding(.horizontal)
            Button("Reintentar", action: retry).buttonStyle(.borderedProminent)
        }
        .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ──────────────────────────────── Preview ────────────────────────────────

#Preview { ReprintObView() }
