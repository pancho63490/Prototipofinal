import Foundation

// Definición del servicio API
struct APIService {
    func fetchData(referenceNumber: String, completion: @escaping (Result<[TrackingData], Error>) -> Void) {
        // Reemplazamos {v} con el valor del referenceNumber
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/search/\(referenceNumber)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Datos inválidos"])))
                return
            }

            // Imprimir datos crudos para depurar
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(DeliveryResponse.self, from: data)
                completion(.success(apiResponse.deliveries))  // Retorna el array de TrackingData
            } catch {
                print("Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
