import SwiftUI
import Combine

class ShipmentState: ObservableObject {
    /// Esta es la propiedad global que almacenará "Inbond" o "Domestic"
    @Published var selectedInboundType: String? = nil
}
