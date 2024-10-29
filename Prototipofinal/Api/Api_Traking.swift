import Foundation

struct APIService {
    func fetchData(referenceNumber: String, completion: @escaping (Result<[TrackingData], Error>) -> Void) {
        let encodedReferenceNumber = referenceNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/search/\(encodedReferenceNumber)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Agrega headers si es necesario
        // request.addValue("Bearer TU_API_KEY", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Imprimir código de estado HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            if let error = error {
                print("Request Error: \(error.localizedDescription)")
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

                if apiResponse.found, let deliveries = apiResponse.deliveries {
                    completion(.success(deliveries))
                } else {
                    // En lugar de devolver un error, devolvemos un array vacío
                    completion(.success([]))
                }
            } catch {
                print("Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
