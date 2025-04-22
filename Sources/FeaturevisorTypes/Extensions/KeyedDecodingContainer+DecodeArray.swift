import Foundation

typealias DecodeElements<T> = (elements: [T], errors: [ArrayElementDecodeError])

extension KeyedDecodingContainer {

    private struct KeyOnlyStructData: Codable {
        let key: String
    }

    private struct EmptyStructData: Codable {}

    func decodeArrayElements<T: Decodable>(
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> DecodeElements<T> where T: Decodable {

        var arrayElements: [T] = []
        var arrayDecodeErrors: [ArrayElementDecodeError] = []

        let container = try nestedUnkeyedContainer(forKey: key)
        var containerCopy = container
        while !containerCopy.isAtEnd {
            if let element = try? containerCopy.decode(T.self) {
                arrayElements.append(element)
            }
            else {
                if let keyStructElement = try? containerCopy.decode(KeyOnlyStructData.self) {
                    arrayDecodeErrors.append(
                        ArrayElementDecodeError(
                            type: String(describing: T.self),
                            key: keyStructElement.key
                        )
                    )
                }
                else {
                    arrayDecodeErrors.append(
                        ArrayElementDecodeError(
                            type: String(describing: T.self),
                            key: "<undefined>"
                        )
                    )
                    _ = try containerCopy.decode(EmptyStructData.self)
                }
            }
        }

        return (elements: arrayElements, errors: arrayDecodeErrors)
    }
}
