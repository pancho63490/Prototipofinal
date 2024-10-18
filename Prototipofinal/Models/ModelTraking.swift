import Foundation

// Modelo para cada TrackingData
struct TrackingData: Codable {
    let externalDeliveryID: String
    let material: String
    let deliveryQty: String
    let deliveryNo: String
    let supplierVendor: String
    let supplierName: String
    let container: String?
    let src: String?
    
    enum CodingKeys: String, CodingKey {
        case externalDeliveryID = "EXTERNAL_DELVRY_ID"
        case material = "MATERIAL"
        case deliveryQty = "DELIVERY_QTY"
        case deliveryNo = "DELIVERY_NO"
        case supplierVendor = "SUPPLIER_VENDOR"
        case supplierName = "SUPPLIER_NAME"
        case container = "CONTAINER"
        case src = "SRC"
    }
}

// Modelo para la respuesta completa
struct DeliveryResponse: Codable {
    let found: Bool
    let deliveries: [TrackingData]
}
