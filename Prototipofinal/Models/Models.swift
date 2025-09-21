import Foundation

enum ScanMethod {
    case cameraScanner
    case manual
    case vision
}



struct ObjectInfo {
    let objectID: String
    let material: String
    var totalQuantity: Int
    var remainingQuantity: Int
    var location: String
    var subItems: [SubItem] = []

    // Inicializador
    init(objectID: String, material: String, totalQuantity: Int, location: String) {
        self.objectID = objectID
        self.material = material
        self.totalQuantity = totalQuantity
        self.remainingQuantity = totalQuantity
        self.location = location
    }
}



/*


// Modelo para representar cada entrada de datos recibida
struct TrackingEntry: Identifiable {
    let id = UUID()
    let objectID: Int
    let material: String
    let location: String
    let quantity: Int
    let bill: String
    
    static func fromTrackingData(_ data: TrackingData) -> TrackingEntry {
        return TrackingEntry(
            objectID: data.objectID,
            material: data.material,
            location: "Desconocido", // Puedes cambiar esto si tienes un valor adecuado
            quantity: Int(data.quantity) ?? 0,
            bill: data.invoiceNumber
        )
    }
}
*/
struct GroupedObject: Identifiable {
    let id = UUID()
    let objectID: Int
    let material: String  // Solo un material por Object ID
    var location: String?
    var totalQuantity: Int
    var remainingQuantity: Int
    let bill: String
    let invoiceNumber: String?
    let quantity: String?
    var deliveryType: String?
    var subItems: [SubItem] = []

    // Inicializador completo
    init(objectID: Int, material: String, location: String, totalQuantity: Int, bill: String, invoiceNumber: String? = nil, quantity: String? = nil, deliveryType: String? = nil) {
        self.objectID = objectID
        self.material = material
        self.location = location
        self.totalQuantity = totalQuantity
        self.remainingQuantity = totalQuantity // Inicializa la cantidad restante
        self.bill = bill
        self.invoiceNumber = invoiceNumber
        self.quantity = quantity
        self.deliveryType = deliveryType
    }
}




struct SubItem: Identifiable {
    let id = UUID()
    let material: String
    let quantity: Int
}

import Foundation
/*
// Extensión para agrupar los datos
extension TrackingEntry {
    static func groupEntriesByObjectID(entries: [TrackingEntry]) -> [GroupedObject] {
        var groupedDict = [Int: GroupedObject]()
        
        for entry in entries {
            if var existingGroup = groupedDict[entry.objectID] {
                // Sumar la cantidad si el Object ID ya existe
                existingGroup.totalQuantity += entry.quantity
                existingGroup.remainingQuantity += entry.quantity
                groupedDict[entry.objectID] = existingGroup // Actualizar el grupo con la nueva cantidad
            } else {
                // Crear un nuevo grupo si no existe
                let newGroup = GroupedObject(
                    objectID: entry.objectID,
                    material: entry.material,
                    location: "Desconocido", // Cambia esto si tienes un valor adecuado
                    totalQuantity: entry.quantity,
                    bill: entry.bill
                )
                groupedDict[entry.objectID] = newGroup
            }
        }
        
        return Array(groupedDict.values)
    }
}
*/
