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

struct DeliveryResponse: Codable {
    let found: Bool
    let deliveries: [TrackingData]?

    // En caso de que la respuesta también incluya un mensaje de error
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
