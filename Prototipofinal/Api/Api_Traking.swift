import Foundation

class APIManager {
    static let shared = APIManager()
    
    // Función para enviar los valores a la API
    func submitShipment(trackingNumber: String, invoiceNumber: String, pallets: String, shipmentType: String, completion: @escaping (Bool) -> Void) {
        
        // Parámetros a enviar
        let parameters: [String: Any] = [
            "trackingNumber": trackingNumber,
            "invoiceNumber": invoiceNumber,
            "pallets": pallets,
            "shipmentType": shipmentType
        ]
        
        // Convertir el diccionario a JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            print("Error serializando los datos.")
            completion(false)
            return
        }
        
        // URL de la API
        let url = URL(string: "https://example.com/api/shipment")! // Reemplaza con la URL de tu API
        
        // Crear la solicitud
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Enviar la solicitud
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud: \(error)")
                completion(false)
                return
            }
            
            // Procesar la respuesta de la API
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true) // Continuar a la siguiente vista
            } else {
                completion(false) // Error en la API
            }
        }
        
        task.resume()
    }
}
