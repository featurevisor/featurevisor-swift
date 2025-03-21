import Foundation

extension KeyedDecodingContainer {

    private struct EmptyStructData: Codable {}

    func decodeArrayElements<T: Decodable>(
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> [T] where T: Decodable {

        var arrayElements: [T] = []

        let container = try nestedUnkeyedContainer(forKey: key)
        var containerCopy = container
        while !containerCopy.isAtEnd {
            if let element = try? containerCopy.decode(T.self) {
                arrayElements.append(element)
            }
            else {
                // @TODO: add error handling for object decoding failed
                _ = try containerCopy.decode(EmptyStructData.self)
            }
        }

        return arrayElements
    }
}
