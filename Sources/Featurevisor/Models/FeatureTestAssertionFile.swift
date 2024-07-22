import FeaturevisorTypes
import Foundation

struct FeatureTestAssertionFile: Decodable {
    var matrix: [String: [String]]?
    var description: String
    var environment: String
    var at: String
    var context: [AttributeKey: AttributeValue]?
    var expectedToBeEnabled: Bool
    var expectedVariables: [ExpectedVariableKey: ExpectedVariableValue]?
}

extension FeatureTestAssertionFile {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matrix = try? container.decode([String: [String]].self, forKey: .matrix)
        description = try container.decode(String.self, forKey: .description)
        environment = try container.decode(String.self, forKey: .environment)
        at = try container.decode(String.self, forKey: .at)
        context = try? container.decode([AttributeKey: AttributeValue].self, forKey: .context)
        expectedToBeEnabled = try container.decode(Bool.self, forKey: .expectedToBeEnabled)
        expectedVariables = try? container.decode(
            [ExpectedVariableKey: ExpectedVariableValue].self,
            forKey: .expectedVariables
        )
    }

    public enum CodingKeys: String, CodingKey {
        case matrix
        case description
        case environment
        case at
        case context
        case expectedToBeEnabled
        case expectedVariables
    }
}

extension FeatureTestAssertionFile {

    func asAssertion() -> Assertion {
        return Assertion(
            description: description,
            environment: Environment(rawValue: environment)!,  // TODO
            at: Double(at)!,  // TODO
            context: context,
            expectedToBeEnabled: expectedToBeEnabled,
            expectedVariables: VariableValueMapper.map(from: expectedVariables)
        )
    }
}
