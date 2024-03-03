import Foundation

extension SingleValueDecodingContainer {

    public func decodeStringified<T>(_ type: T.Type) throws -> T
    where T: Decodable {

        if let object = try? self.decode(type) {
            return object
        }

        let string = try? self.decode(String.self)

        guard let data = string?.data(using: .utf8) else {

            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Featurevisor: DataCorrupted when decoding: \(type.self)"
            )

            throw DecodingError.dataCorrupted(context)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
