import SwiftUI

func sendToAPI(jsonData: [[String: Any]]) {
    // Asegúrate de que la URL esté bien formada con el esquema correcto
    guard let url = URL(string: "https://ews-emea.api.bosch.com/Api_XDock/api/update") else {
        print("URL no válida")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        // Convertir el diccionario JSON a data
        let data = try JSONSerialization.data(withJSONObject: jsonData, options: [])
        request.httpBody = data
        
        // Iniciar la tarea de URLSession para hacer la solicitud
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error al enviar datos: \(error.localizedDescription)")
                return
            }
            
            // Verificar si se recibió alguna respuesta
            if let httpResponse = response as? HTTPURLResponse {
                print("Código de respuesta HTTP: \(httpResponse.statusCode)")
            }

            print("Datos enviados correctamente")
        }
        
        // Iniciar la solicitud
        task.resume()
    } catch {
        print("Error al serializar JSON: \(error.localizedDescription)")
    }
}
