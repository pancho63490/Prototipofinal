import Foundation

struct ObjectIDResponse: Decodable {
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
        
        
        if let msg = try? container.decode(String.self, forKey: .messageUpper) {
            message = msg
        } else if let msg = try? container.decode(String.self, forKey: .messageLower) {
            message = msg
        } else {
            message = ""
        }
        
        
        if let ids = try? container.decode([Int].self, forKey: .objectIDs) {
            objectIDs = ids
        } else if let ids = try? container.decode([Int].self, forKey: .objectIDsAlternative) {
            objectIDs = ids
        } else {
            objectIDs = nil
        }
    }
}

struct BackupObjectIDResponse: Decodable {
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
        
        
        if let msg = try? container.decode(String.self, forKey: .messageUpper) {
            message = msg
        } else if let msg = try? container.decode(String.self, forKey: .messageLower) {
            message = msg
        } else {
            message = ""
        }
        
        
        if let ids = try? container.decode([Int].self, forKey: .objectIDs) {
            objectIDs = ids
        } else if let ids = try? container.decode([Int].self, forKey: .objectIDsAlternative) {
            objectIDs = ids
        } else {
            objectIDs = nil
        }
    }
}
