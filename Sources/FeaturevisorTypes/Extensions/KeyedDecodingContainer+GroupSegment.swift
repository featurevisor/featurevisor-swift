import Foundation

extension KeyedDecodingContainer {

    func decodeGroupSegmentIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws
        -> GroupSegment?
    {

        guard self.contains(key) else {
            return nil
        }

        return try decodeGroupSegment(forKey: key)
    }

    func decodeGroupSegment(forKey key: KeyedDecodingContainer<K>.Key) throws -> GroupSegment {

        let stringifiedGroupSegment = try self.decode(String.self, forKey: key)

        switch stringifiedGroupSegment {
            case "*":
                return .plain(stringifiedGroupSegment)
            default:
                guard let data = stringifiedGroupSegment.data(using: .utf8) else {

                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription:
                            "Featurevisor: DataCorrupted when decoding: \(GroupSegment.self)"
                    )

                    throw DecodingError.dataCorrupted(context)
                }

                guard
                    let _ = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                else {
                    return .plain(stringifiedGroupSegment)
                }

                return try JSONDecoder().decode(GroupSegment.self, from: data)
        }
    }
}
