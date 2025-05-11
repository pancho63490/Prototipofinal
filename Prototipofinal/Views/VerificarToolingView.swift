import SwiftUI

// MARK: - Data Models
struct InsertMaterialDTO: Identifiable, Codable, Hashable {
    let id = UUID()
    let material: String
    let quantity: Int
    let grossWeight: String
    let netWeight: String
    let details: String

    var formattedDetails: String {
        "Qty: \(quantity) | Gross: \(grossWeight) | Net: \(netWeight)"
    }
}

struct InsertToolingResponse: Codable {
    let vendor: String
    let orderNumber: String
    let date: String
    let materials: [InsertMaterialDTO]
    let objectIDs: [String]
}

// MARK: - Service Protocol
protocol InsertToolingServiceProtocol {
    func fetchToolingInfo(trackingNumber: String) async throws -> InsertToolingResponse
}

// MARK: - Mock Service
class InsertToolingService: InsertToolingServiceProtocol {
    func fetchToolingInfo(trackingNumber: String) async throws -> InsertToolingResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let materials = [
            InsertMaterialDTO(material: "MAT-001", quantity: 5, grossWeight: "10.5", netWeight: "9.8", details: "Fragile"),
            InsertMaterialDTO(material: "MAT-002", quantity: 3, grossWeight: "7.2", netWeight: "6.5", details: "")
        ]
        return InsertToolingResponse(
            vendor: "ACME Tools",
            orderNumber: "ORD-12345",
            date: ISO8601DateFormatter().string(from: Date()),
            materials: materials,
            objectIDs: ["OBJ-001", "OBJ-002", "OBJ-003"]
        )
    }
}

@MainActor
class VerificarToolingViewModel: ObservableObject {
    enum ViewState {
        case idle, loading, selectObject, selectMaterials(String),
             enterQuantities(objectID: String, materials: [InsertMaterialDTO]),
             review, error(String)
    }

    // MARK: - Published Properties
    @Published var state: ViewState = .idle
    @Published var trackingNo = ""
    @Published var selectedObjectID: String?
    @Published var selectedMaterials: [UUID: Int] = [:]
    @Published var selectionOrder: [UUID] = [] // Tracks selection order
    @Published var assignedObjects: [String: [UUID: Int]] = [:]
    @Published var remainingMaterials: [UUID: Int] = [:]
    @Published var hasUnassignedObjects = false
    @Published var currentObjectID: String?
    @Published var allObjectIDs: [String] = []
    
    // MARK: - Editing State
    private var preEditState: (assignedObjects: [String: [UUID: Int]], remainingMaterials: [UUID: Int])?
    @Published var isEditing = false

    // MARK: - Internal Properties
    private(set) var response: InsertToolingResponse?
    private let service: InsertToolingServiceProtocol

    init(service: InsertToolingServiceProtocol = InsertToolingService()) {
        self.service = service
    }

    // MARK: - Computed Properties
    var availableObjectIDs: [String] { allObjectIDs.filter { !assignedObjects.keys.contains($0) } }
    var allMaterialsAssigned: Bool { remainingMaterials.values.allSatisfy { $0 == 0 } }
    var assignedMaterialsCount: [String: Int] {
        Dictionary(uniqueKeysWithValues: assignedObjects.map { ($0.key, $0.value.count) })
    }

    // MARK: - Public Methods
    
    func loadInfo() async {
        guard !trackingNo.isEmpty else { return }
        state = .loading
        resetAssignments()
        do {
            response = try await service.fetchToolingInfo(trackingNumber: trackingNo)
            if let res = response {
                remainingMaterials = Dictionary(uniqueKeysWithValues: res.materials.map { ($0.id, $0.quantity) })
                allObjectIDs = res.objectIDs
            }
            state = .selectObject
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func selectObjectID(_ id: String) {
        selectedObjectID = id
        currentObjectID = id
        state = .selectMaterials(id)
    }

    func toggleMaterialSelection(_ materialID: UUID) {
        if selectedMaterials[materialID] != nil {
            selectedMaterials.removeValue(forKey: materialID)
            selectionOrder.removeAll { $0 == materialID }
        } else {
            selectedMaterials[materialID] = 0 // Initialize with 0 quantity
            selectionOrder.append(materialID) // Track order
        }
    }

    func editObjectAssignment(_ objectID: String) {
        // Save current state before editing
        preEditState = (assignedObjects, remainingMaterials)
        isEditing = true
        
        selectedObjectID = objectID
        currentObjectID = objectID
        
        if let assigned = assignedObjects[objectID] {
            selectedMaterials = assigned
            // Temporarily return materials to available pool
            for (matID, qty) in assigned {
                remainingMaterials[matID, default: 0] += qty
                if !selectionOrder.contains(matID) {
                    selectionOrder.append(matID)
                }
            }
            assignedObjects.removeValue(forKey: objectID)
        }
        
        state = .selectMaterials(objectID)
    }

    func completeAssignment() {
        guard let objectID = selectedObjectID else { return }
        
        // Apply new assignment in selection order
        for matID in selectionOrder {
            if let qty = selectedMaterials[matID] {
                remainingMaterials[matID, default: 0] -= qty
            }
        }
        
        assignedObjects[objectID] = selectedMaterials
        cleanupAfterAssignment()
        
        // Return to appropriate state
        hasUnassignedObjects = availableObjectIDs.isEmpty == false
        state = (availableObjectIDs.isEmpty || allMaterialsAssigned) ? .review : .selectObject
    }
    
    func cancelEditing() {
        if let preEditState = preEditState {
            // Restore previous state
            assignedObjects = preEditState.assignedObjects
            remainingMaterials = preEditState.remainingMaterials
        }
        cleanupAfterAssignment()
        state = .selectObject
    }

    func submitVerification() {
        let payload: [String: Any] = [
            "trackingNumber": trackingNo,
            "assignments": assignedObjects,
            "remainingMaterials": remainingMaterials,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        print("Submitting verification:", payload)
    }

    func navigateBack() {
        switch state {
        case .selectMaterials:
            if isEditing {
                cancelEditing()
            } else {
                state = .selectObject
            }
        case .enterQuantities(let objectID, _):
            state = .selectMaterials(objectID)
        case .review:
            state = .selectObject
        default: break
        }
    }

    func hasUnsavedChanges(_ selectedMaterials: [InsertMaterialDTO], _ quantityInputs: [UUID: String]) -> Bool {
        switch state {
        case .selectMaterials: return !selectedMaterials.isEmpty
        case .enterQuantities: return quantityInputs.values.contains { !$0.isEmpty }
        default: return false
        }
    }

    // MARK: - Private Methods
    
    private func cleanupAfterAssignment() {
        selectedMaterials = [:]
        selectionOrder = []
        selectedObjectID = nil
        currentObjectID = nil
        isEditing = false
        preEditState = nil
    }
    
    private func resetAssignments() {
        selectedObjectID = nil
        currentObjectID = nil
        selectedMaterials = [:]
        selectionOrder = []
        assignedObjects = [:]
        remainingMaterials = [:]
        hasUnassignedObjects = false
        isEditing = false
        preEditState = nil
    }
}

struct VerificarToolingView: View {
    @StateObject private var vm = VerificarToolingViewModel()
    @State private var showSubmissionAlert = false
    @State private var showConfirmAlert = false
    @State private var selectedMaterials: [InsertMaterialDTO] = []
    @State private var quantityInputs: [UUID: String] = [:]
    @State private var showQuantityError = false
    @State private var quantityErrorMaterial: InsertMaterialDTO?
    @State private var showExitConfirmation = false
    @State private var originalAssignments: [String: [UUID: Int]] = [:]
    @State private var originalRemaining: [UUID: Int] = [:]
    @State private var selectedObjectID: String?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tooling Verification")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .alert("Verification Submitted", isPresented: $showSubmissionAlert) {
                    Button("OK", role: .cancel) { resetAll() }
                }
                .alert("Confirm Submission", isPresented: $showConfirmAlert) {
                    Button("Submit", role: .destructive) {
                        vm.submitVerification()
                        showSubmissionAlert = true
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    submissionConfirmationMessage
                }
                .alert("Quantity Exceeds Available", isPresented: $showQuantityError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if let mat = quantityErrorMaterial {
                        Text("You cannot assign \(quantityInputs[mat.id] ?? "") to \(mat.material). Only \(vm.remainingMaterials[mat.id] ?? 0) available.")
                    }
                }
                .alert("Unsaved Changes", isPresented: $showExitConfirmation) {
                    Button("Leave", role: .destructive) {
                        handleNavigationBack()
                    }
                    Button("Stay", role: .cancel) { }
                } message: {
                    Text("You have unsaved changes. Are you sure you want to leave?")
                }
        }
    }
    
    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle: idleView
        case .loading: loadingView
        case .selectObject: selectObjectView
        case .selectMaterials(let id): selectMaterialsView(for: id)
        case .enterQuantities(let id, _): enterQuantitiesView(for: id)
        case .review: reviewView
        case .error(let msg): ErrorView(message: msg, retry: { Task { await vm.loadInfo() } })
        }
    }
    
    // MARK: - View Components
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Tooling Verification")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Enter tracking number to begin verification process")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            HStack {
                TextField("Tracking Number", text: $vm.trackingNo)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: { Task { await vm.loadInfo() } }) {
                    Label("Load", systemImage: "arrow.right")
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.trackingNo.isEmpty)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Tooling Information...")
                .padding(.top, 20)
            Spacer()
        }
    }
    
    private var selectObjectView: some View {
        Form {
            Section {
                Picker("Select Object ID", selection: $selectedObjectID) {
                    Text("Choose an object").tag(nil as String?)
                    ForEach(vm.allObjectIDs, id: \.self) { id in
                        Text(id).tag(id as String?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedObjectID) { newValue in
                    if let id = newValue {
                        vm.selectObjectID(id)
                    }
                }
                
                if let selectedID = selectedObjectID {
                    if let assigned = vm.assignedObjects[selectedID] {
                        DisclosureGroup("Assigned Materials (\(assigned.count))") {
                            ForEach(Array(assigned.keys), id: \.self) { matID in
                                if let material = vm.response?.materials.first(where: { $0.id == matID }) {
                                    HStack {
                                        Text(material.material)
                                        Spacer()
                                        Text("\(assigned[matID] ?? 0)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Button("Edit Assignment") {
                            prepareForEditing(objectID: selectedID)
                        }
                    } else {
                        Button("Assign Materials") {
                            vm.selectObjectID(selectedID)
                        }
                    }
                }
            }
            
            if selectedObjectID != nil {
                Section("Available Materials") {
                    if let materials = vm.response?.materials {
                        MaterialPickerView(
                            viewModel: vm,
                            materials: materials,
                            remainingMaterials: vm.remainingMaterials,
                            selectedMaterials: $selectedMaterials,
                            searchText: $searchText
                        )
                    }
                }
            }
        }
    }
    
    private func selectMaterialsView(for objectID: String) -> some View {
        Form {
            Section("Select Materials for \(objectID)") {
                if let materials = filteredMaterials {
                    List {
                        ForEach(materials) { material in
                            HStack {
                                if let index = vm.selectionOrder.firstIndex(of: material.id) {
                                    Text("\(index + 1)")
                                        .frame(width: 24)
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .frame(width: 24)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(material.material)
                                    Text("Available: \(vm.remainingMaterials[material.id] ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.toggleMaterialSelection(material.id)
                                if vm.selectedMaterials[material.id] != nil {
                                    selectedMaterials.append(material)
                                } else {
                                    selectedMaterials.removeAll { $0.id == material.id }
                                }
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Continue") {
                    if !selectedMaterials.isEmpty {
                        vm.state = .enterQuantities(objectID: objectID, materials: selectedMaterials)
                        quantityInputs = Dictionary(
                            uniqueKeysWithValues: selectedMaterials.map { ($0.id, "") }
                        )
                    }
                }
                .disabled(selectedMaterials.isEmpty)
            }
        }
        .searchable(text: $searchText, prompt: "Search materials")
        .navigationBarBackButtonHidden(true)
    }
    
    private func enterQuantitiesView(for objectID: String) -> some View {
        Form {
            Section("Enter Quantities for \(objectID)") {
                // Show materials in selection order
                ForEach(vm.selectionOrder.compactMap { matID in
                    selectedMaterials.first { $0.id == matID }
                }, id: \.id) { mat in
                    HStack {
                        Text(mat.material)
                        Spacer()
                        TextField("Qty", text: Binding(
                            get: { quantityInputs[mat.id, default: ""] },
                            set: { quantityInputs[mat.id] = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                    }
                }
            }
            
            Section {
                Button(vm.assignedObjects[objectID] != nil ? "Update Assignment" : "Complete Assignment") {
                    validateAndCompleteAssignment()
                }
                .disabled(!isQuantityInputValid)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var reviewView: some View {
        Form {
            if let res = vm.response {
                Section("Order Information") {
                    InfoRow(label: "Vendor", value: res.vendor, icon: "building.2")
                    InfoRow(label: "Order Number", value: res.orderNumber, icon: "number")
                    InfoRow(label: "Date", value: formattedDate(res.date), icon: "calendar")
                }
            }
            
            Section("Material Assignments") {
                ForEach(vm.allObjectIDs, id: \.self) { oid in
                    DisclosureGroup(oid) {
                        if let materials = vm.assignedObjects[oid] {
                            ForEach(Array(materials.keys), id: \.self) { matID in
                                if let mat = vm.response?.materials.first(where: { $0.id == matID }) {
                                    HStack {
                                        Text(mat.material)
                                        Spacer()
                                        Text("\(materials[matID] ?? 0)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if !vm.allMaterialsAssigned {
                Section("Remaining Materials") {
                    ForEach(vm.response?.materials ?? []) { mat in
                        if let rem = vm.remainingMaterials[mat.id], rem > 0 {
                            HStack {
                                Text(mat.material)
                                Spacer()
                                Text("\(rem) remaining")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") { showConfirmAlert = true }
            }
        }
    }
    
    // MARK: - Componentes Reutilizables
    
    struct MaterialPickerView: View {
        @ObservedObject var viewModel: VerificarToolingViewModel
        let materials: [InsertMaterialDTO]
        let remainingMaterials: [UUID: Int]
        @Binding var selectedMaterials: [InsertMaterialDTO]
        @Binding var searchText: String
        
        var filteredMaterials: [InsertMaterialDTO] {
            if searchText.isEmpty {
                return materials.filter { remainingMaterials[$0.id] ?? 0 > 0 }
            } else {
                return materials.filter {
                    ($0.material.localizedCaseInsensitiveContains(searchText) &&
                     (remainingMaterials[$0.id] ?? 0 > 0))
                }
            }
        }
        
        var body: some View {
            List {
                ForEach(filteredMaterials) { material in
                    HStack {
                        if let index = viewModel.selectionOrder.firstIndex(of: material.id) {
                            Text("\(index + 1)")
                                .frame(width: 24)
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .frame(width: 24)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(material.material)
                            Text("Available: \(remainingMaterials[material.id] ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleMaterialSelection(material.id)
                        if viewModel.selectedMaterials[material.id] != nil {
                            selectedMaterials.append(material)
                        } else {
                            selectedMaterials.removeAll { $0.id == material.id }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    struct MaterialRow: View {
        let material: InsertMaterialDTO
        
        var body: some View {
            HStack {
                Text(material.material)
                Spacer()
                Text("Available: \(material.quantity)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    struct InfoRow: View {
        let label: String
        let value: String
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(label)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Funciones auxiliares
    
    private var filteredMaterials: [InsertMaterialDTO]? {
        guard let materials = vm.response?.materials else { return nil }
        
        if searchText.isEmpty {
            return materials.filter { vm.remainingMaterials[$0.id] ?? 0 > 0 }
        } else {
            return materials.filter {
                $0.material.localizedCaseInsensitiveContains(searchText) &&
                (vm.remainingMaterials[$0.id] ?? 0 > 0)
            }
        }
    }
    
    private func prepareForEditing(objectID: String) {
        originalAssignments = vm.assignedObjects
        originalRemaining = vm.remainingMaterials
        vm.editObjectAssignment(objectID)
        selectedMaterials = getAssignedMaterials(for: objectID).map {
            vm.response?.materials.first { $0.id == $0.id } ?? InsertMaterialDTO(
                material: $0.material,
                quantity: $0.quantity,
                grossWeight: "",
                netWeight: "",
                details: ""
            )
        }
        vm.state = .selectMaterials(objectID)
    }
    
    private func getAssignedMaterials(for objectID: String) -> [AssignedMaterial] {
        guard let materials = vm.assignedObjects[objectID],
              let allMaterials = vm.response?.materials else {
            return []
        }
        
        return materials.compactMap { materialID, quantity in
            allMaterials.first { $0.id == materialID }.map {
                AssignedMaterial(id: materialID, material: $0.material, quantity: quantity)
            }
        }
    }
    
    private func validateAndCompleteAssignment() {
        var temp: [UUID: Int] = [:]
        
        // Process in selection order
        for matID in vm.selectionOrder {
            guard let input = quantityInputs[matID],
                  let qty = Int(input),
                  qty > 0 else {
                continue
            }
            
            let remaining = vm.remainingMaterials[matID] ?? 0
            if qty > remaining {
                quantityErrorMaterial = vm.response?.materials.first { $0.id == matID }
                showQuantityError = true
                return
            }
            
            temp[matID] = qty
        }
        
        vm.selectedMaterials = temp
        vm.completeAssignment()
        selectedMaterials.removeAll()
        quantityInputs.removeAll()
        originalAssignments = [:]
        originalRemaining = [:]
    }
    
    private func handleNavigationBack() {
        vm.navigateBack()
        selectedMaterials.removeAll()
        quantityInputs.removeAll()
        
        if !originalAssignments.isEmpty {
            vm.assignedObjects = originalAssignments
            vm.remainingMaterials = originalRemaining
            originalAssignments = [:]
            originalRemaining = [:]
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if case .review = vm.state {
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") { showConfirmAlert = true }
            }
        }

        if shouldShowBackButton {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if vm.hasUnsavedChanges(selectedMaterials, quantityInputs) {
                        showExitConfirmation = true
                    } else {
                        handleNavigationBack()
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }
    
    private var shouldShowBackButton: Bool {
        switch vm.state {
        case .idle, .loading: return false
        default: return true
        }
    }
    
    private var isQuantityInputValid: Bool {
        for matID in vm.selectionOrder {
            guard let input = quantityInputs[matID], !input.isEmpty,
                  let qty = Int(input), qty > 0,
                  qty <= (vm.remainingMaterials[matID] ?? 0) else {
                return false
            }
        }
        return !selectedMaterials.isEmpty
    }
    
    @ViewBuilder
    private var submissionConfirmationMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirm Submission")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if vm.hasUnassignedObjects {
                Label {
                    Text("Some Object IDs don't have materials assigned")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            if !vm.allMaterialsAssigned {
                Label {
                    Text("There are remaining materials not assigned")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            Text("Are you sure you want to submit with current assignments?")
                .font(.subheadline)
        }
        .padding()
    }
    
    private func formattedDate(_ iso: String) -> String {
        let df = ISO8601DateFormatter()
        guard let date = df.date(from: iso) else { return iso }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
    
    private func resetAll() {
        vm.state = .idle
        vm.trackingNo = ""
        selectedMaterials.removeAll()
        quantityInputs.removeAll()
        originalAssignments = [:]
        originalRemaining = [:]
        selectedObjectID = nil
        searchText = ""
    }
}

// Estructura para materiales asignados
struct AssignedMaterial: Identifiable {
    let id: UUID
    let material: String
    let quantity: Int
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50)).foregroundColor(.red)
            Text("Error").font(.title).foregroundColor(.red)
            Text(message).multilineTextAlignment(.center).padding(.horizontal)
            Button("Try Again", action: retry).buttonStyle(.borderedProminent)
        }.frame(maxHeight: .infinity)
    }
}
