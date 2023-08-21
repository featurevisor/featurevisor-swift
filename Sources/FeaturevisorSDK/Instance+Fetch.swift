import FeaturevisorTypes
import Foundation

internal extension FeaturevisorInstance {
    
    func fetchDatafileContent(
        from url: String,
        completion: @escaping (Result<DatafileContent, Error>) -> Void) {
        
        guard let datafileUrl = URL(string: url) else {
            completion(.failure(FeaturevisorError.invalidURL(string: url)))
            return
        }
        
        var request = URLRequest(url: datafileUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        fetch(using: request, completion: completion)
    }
}

private extension FeaturevisorInstance {
    
    func fetch<T>(using request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
        
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let content = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(content))
                } catch {
                    completion(.failure(FeaturevisorError.unparseableJSON(data: data, errorMessage: error.localizedDescription)))
                }
            }
        }
        
        task.resume()
    }
}
