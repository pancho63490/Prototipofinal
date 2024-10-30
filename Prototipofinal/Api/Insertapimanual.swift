import Foundation

class DeliveryAPIService {
    static let shared = DeliveryAPIService()
    
    private init() {}
    
    func sendTrackingData(_ data: TrackingData, completion: @escaping (Result<Void, Error>) -> Void) {
        // Reemplaza con la URL de tu API
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/insertManual") else {
            completion(.failure(APIError2.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // Establecer encabezados si es necesario
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(APIError2.encodingError))
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Manejar errores de red
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Verificar la respuesta del servidor
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    completion(.failure(APIError2.serverError(statusCode: httpResponse.statusCode)))
                }
            } else {
                completion(.failure(APIError2.unknown))
            }
        }
        
        task.resume()
    }
}

// Definición de errores personalizados
enum APIError2: Error, LocalizedError {
    case invalidURL
    case encodingError
    case serverError(statusCode: Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .encodingError:
            return "Error al codificar los datos."
        case .serverError(let statusCode):
            return "Error del servidor con código: \(statusCode)."
        case .unknown:
            return "Error desconocido."
        }
    }
}
