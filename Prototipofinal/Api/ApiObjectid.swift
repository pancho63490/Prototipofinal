import Foundation

class APIServiceobj {
    func requestObjectIDs(requestData: [String: Any], completion: @escaping (Result<ObjectIDResponse, Error>) -> Void) {
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/insert") else {
            print("URL inválida")
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convertir el cuerpo del requestData en JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData, options: [])
            if let jsonBody = String(data: request.httpBody!, encoding: .utf8) {
                print("Request JSON Body: \(jsonBody)") // Para depurar el cuerpo de la solicitud
            }
        } catch {
            print("Error serializando el cuerpo JSON: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("Datos inválidos o vacíos")
                completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Datos inválidos"])))
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)") // Para depurar la respuesta del servidor
            }

            do {
                let decoder = JSONDecoder()
                let objectIDResponse = try decoder.decode(ObjectIDResponse.self, from: data)
                print("Object IDs recibidos: \(objectIDResponse.objectIDs)")
                completion(.success(objectIDResponse))
            } catch {
                print("Error decodificando la respuesta: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

// Modelo para la respuesta de los Object IDs
struct ObjectIDResponse: Codable {
    let message: String
    let objectIDs: [Int]  // Mapeo de la clave "objectIds"

    enum CodingKeys: String, CodingKey {
        case message
        case objectIDs = "objectIds"  // Mapeo correcto desde el JSON
    }
}
