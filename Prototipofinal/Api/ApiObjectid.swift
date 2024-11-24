import Foundation

class APIServiceobj {
    // Definición de los posibles errores
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidRequestBody
        case noData
        case networkError(Error)
        case decodingError(Error)
        case objectIDsAlreadyExist(message: String)
        case unknownError(message: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL inválida."
            case .invalidRequestBody:
                return "Cuerpo de solicitud inválido."
            case .noData:
                return "No se recibió ningún dato."
            case .networkError(let error):
                return "Error de red: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Error de decodificación: \(error.localizedDescription)"
            case .objectIDsAlreadyExist(let message):
                return message
            case .unknownError(let message):
                return message
            }
        }
    }
    
    // Función para la primera API: Solicitar Object IDs
    func requestObjectIDs(requestData: [String: Any], completion: @escaping (Result<ObjectIDResponse, APIError>) -> Void) {
        guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/insert") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // Método POST según la API
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData, options: [])
            print("Cuerpo de la solicitud JSON creado exitosamente.")
        } catch {
            print("Error al crear el cuerpo de la solicitud JSON: \(error.localizedDescription)")
            completion(.failure(.invalidRequestBody))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud a la API: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("No se recibió ningún dato en la respuesta de la API.")
                completion(.failure(.noData))
                return
            }
            
            print("Datos de respuesta recibidos: \(String(data: data, encoding: .utf8) ?? "Datos no legibles")")
            
            do {
                let decoder = JSONDecoder()
                let objectIDResponse = try decoder.decode(ObjectIDResponse.self, from: data)
                
                // Verificar el mensaje para determinar el resultado
                if objectIDResponse.message.contains("SUCCESSFULLY CREATED") {
                    completion(.success(objectIDResponse))
                } else if objectIDResponse.message.contains("SUCCESSFULLY FOUND") {
                    completion(.failure(.objectIDsAlreadyExist(message: objectIDResponse.message)))
                } else {
                    completion(.failure(.unknownError(message: objectIDResponse.message)))
                }
            } catch {
                print("Error al decodificar ObjectIDResponse: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
    
    // Función para la segunda API: Buscar Object IDs
    func searchObjectIDs(x: String, completion: @escaping (Result<BackupObjectIDResponse, APIError>) -> Void) {
        let urlString = "https://ews-emea.api.bosch.com/Api_XDock/api/searchOb/\(x)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Método GET según la API
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud a la API de búsqueda: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("No se recibió ningún dato en la respuesta de la API de búsqueda.")
                completion(.failure(.noData))
                return
            }
            
            print("Datos de respuesta recibidos de búsqueda: \(String(data: data, encoding: .utf8) ?? "Datos no legibles")")
            
            do {
                let decoder = JSONDecoder()
                let backupResponse = try decoder.decode(BackupObjectIDResponse.self, from: data)
                completion(.success(backupResponse))
            } catch {
                print("Error al decodificar BackupObjectIDResponse: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
}
