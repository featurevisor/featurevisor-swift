import FeaturevisorTypes
import Foundation

extension FeaturevisorInstance {

    // MARK: - Fetch datafile content

    func fetchDatafileContent(
        from url: String,
        handleDatafileFetch: DatafileFetchHandler? = nil,
        completion: @escaping (Result<DatafileContent, Error>) -> Void
    ) throws {

        guard let handleDatafileFetch else {
            try fetchDatafileContent(from: url, completion: completion)
            return
        }

        completion(handleDatafileFetch(url))
    }
}

extension FeaturevisorInstance {

    fileprivate func fetchDatafileContent(
        from url: String,
        completion: @escaping (Result<DatafileContent, Error>) -> Void
    ) throws {

        guard let datafileUrl = URL(string: url) else {
            throw FeaturevisorError.invalidURL(string: url)
        }

        var request = URLRequest(url: datafileUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        fetch(using: request, completion: completion)
    }

    fileprivate func fetch<T>(
        using request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) where T: Decodable {

        let task = urlSession.dataTask(with: request) { (data, response, error) in

            if let error = error {
                completion(.failure(error))
            }
            else if let data = data {
                do {
                    let content = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(content))
                }
                catch {
                    completion(
                        .failure(
                            FeaturevisorError.unparseableJSON(
                                data: data,
                                errorMessage: error.localizedDescription
                            )
                        )
                    )
                }
            }
        }

        task.resume()
    }
}
