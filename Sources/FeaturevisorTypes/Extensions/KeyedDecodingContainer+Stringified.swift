import Foundation

extension KeyedDecodingContainer {

    func decodeStringified<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T
    where T: Decodable {

        if let object = try? self.decode(type, forKey: key) {
            return object
        }

        let stringifiedConditions = try self.decodeIfPresent(String.self, forKey: key)

        guard let data = stringifiedConditions?.data(using: .utf8) else {

            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Featurevisor: DataCorrupted when decoding: \(type.self)"
            )

            throw DecodingError.dataCorrupted(context)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func decodeStringifiedIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key)
        throws -> T? where T: Decodable
    {

        guard self.contains(key) else {
            return nil
        }

        return try decodeStringified(type, forKey: key)
    }
}
