import Foundation

// Modelo de los datos de envío
struct ShipmentData: Codable {
    var carrierName: String
    var driverName: String
    var truckNumber: String
    var numInbonds: String
    var palletsQuantity: String?
    var boxesQuantity: String?
    var damagedPallets: String?
    var damagedBoxes: String?
    var additionalComments: String?
    var truckArrivalDate: Date
}

// Servicio para enviar los datos de envío a la API
class APIServicioManual {
    func sendShipmentData(_ shipmentData: ShipmentData, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://ews-esz-emea.api.bosch.com/Api_XDock/api/insert") else { // Cambia por la URL de tu API
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL no válida."])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(shipmentData)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Respuesta no válida del servidor."])))
                return
            }
            
            completion(.success("Datos enviados correctamente"))
        }.resume()
    }
}
