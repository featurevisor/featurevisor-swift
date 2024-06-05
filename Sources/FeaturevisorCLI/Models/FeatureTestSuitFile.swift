import FeaturevisorTypes
import Foundation

struct FeatureTestSuitFile: Decodable {
    var feature: String
    var assertions: [Assertion]
}

extension FeatureTestSuitFile {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        feature = try container.decode(String.self, forKey: .feature)

        let _assertions = try container.decode([FeatureTestAssertionFile].self, forKey: .assertions)
        assertions = AssertionMapper.map(from: _assertions)
    }

    public enum CodingKeys: String, CodingKey {
        case feature
        case assertions
    }
}
