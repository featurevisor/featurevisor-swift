import Foundation

extension DatafileContent {

    public static func from(string datafileJSONString: String) throws -> DatafileContent? {

        guard let data = datafileJSONString.data(using: .utf8) else {
            return nil
        }

        return try JSONDecoder().decode(DatafileContent.self, from: data)
    }
}
