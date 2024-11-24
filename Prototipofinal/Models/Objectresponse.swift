import Foundation

struct ObjectIDResponse: Decodable { // Cambiado de Codable a Decodable
    let message: String
    let objectIDs: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case messageUpper = "Message"
        case messageLower = "message"
        case objectIDs = "objectIds"
        case objectIDsAlternative = "objectIDs"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decodificar el mensaje, manejando ambas variantes
        if let msg = try? container.decode(String.self, forKey: .messageUpper) {
            message = msg
        } else if let msg = try? container.decode(String.self, forKey: .messageLower) {
            message = msg
        } else {
            message = ""
        }
        
        // Decodificar los Object IDs, manejando ambas variantes si es necesario
        if let ids = try? container.decode([Int].self, forKey: .objectIDs) {
            objectIDs = ids
        } else if let ids = try? container.decode([Int].self, forKey: .objectIDsAlternative) {
            objectIDs = ids
        } else {
            objectIDs = nil
        }
    }
}

struct BackupObjectIDResponse: Decodable { // Cambiado de Codable a Decodable
    let message: String
    let objectIDs: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case messageUpper = "Message"
        case messageLower = "message"
        case objectIDs = "objectIds"
        case objectIDsAlternative = "objectIDs"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decodificar el mensaje, manejando ambas variantes
        if let msg = try? container.decode(String.self, forKey: .messageUpper) {
            message = msg
        } else if let msg = try? container.decode(String.self, forKey: .messageLower) {
            message = msg
        } else {
            message = ""
        }
        
        // Decodificar los Object IDs, manejando ambas variantes si es necesario
        if let ids = try? container.decode([Int].self, forKey: .objectIDs) {
            objectIDs = ids
        } else if let ids = try? container.decode([Int].self, forKey: .objectIDsAlternative) {
            objectIDs = ids
        } else {
            objectIDs = nil
        }
    }
}
