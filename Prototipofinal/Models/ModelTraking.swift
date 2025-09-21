import Foundation
struct TrackingData: Codable, Identifiable {
    let id = UUID()
    var externalDeliveryID: String
    let material: String
    let deliveryQty: String
    let deliveryNo: String
    let supplierVendor: String
    let supplierName: String
    let container: String?
    let src: String?
    let unit: String
    let pesoBruto: Decimal?
    let pesoNeto: Decimal?
    var grouping: String?
   
    
    enum CodingKeys: String, CodingKey {
        case externalDeliveryID = "EXTERNAL_DELVRY_ID"
        case material = "MATERIAL"
        case deliveryQty = "DELIVERY_QTY"
        case deliveryNo = "DELIVERY_NO"
        case supplierVendor = "SUPPLIER_VENDOR"
        case supplierName = "SUPPLIER_NAME"
        case container = "CONTAINER"
        case src = "SRC"
        case unit = "UNIT"
        case pesoBruto = "Peso_bruto"
        case pesoNeto = "Peso_neto"
        case grouping = "GROUPING_NUMBER"
    }
}

struct DeliveryResponse: Codable {
    let found: Bool
    let deliveries: [TrackingData]?


    let message: String?

    enum CodingKeys: String, CodingKey {
        case found = "found"
        case deliveries = "deliveries"
        case message = "message"
    }
}


enum APIError: Error {
    case notFound
    case serverError
    case unknown
}

import Foundation

struct DeliveryRequest: Codable {
    let externalDeliveryID: String
    let deliveryNo: String
    let supplierVendor: String
    let supplierName: String
    let truckReference: String
    let providerReference: String
    let materials: [MaterialRequest]
    let container: String?
    let src: String?
}

struct MaterialRequest: Codable, Identifiable {
    let id = UUID()
    let material: String
    let deliveryQty: String
}
