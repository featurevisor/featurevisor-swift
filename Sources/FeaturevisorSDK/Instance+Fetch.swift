import FeaturevisorTypes
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension FeaturevisorInstance {

    // MARK: - Fetch datafile content

    func fetchDatafileContent(
        from url: String,
        handleDatafileFetch: DatafileFetchHandler? = nil,
        completion: @escaping (Result<DatafileContent, Error>) -> Void
    ) throws {

        guard let datafileURL = URL(string: url) else {
            throw FeaturevisorError.invalidURL(string: url)
        }

        guard let handleDatafileFetch else {
            fetch(from: datafileURL, completion: completion)
            return
        }

        Task {
            completion(await handleDatafileFetch(datafileURL))
        }
    }
}

extension FeaturevisorInstance {

    fileprivate func fetch<T>(
        from url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) where T: Decodable {

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

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
