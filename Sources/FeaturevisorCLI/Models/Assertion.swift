import FeaturevisorTypes
import Foundation

struct Assertion {
    var description: String
    var environment: Environment
    var at: Double
    var context: [AttributeKey: AttributeValue]?
    var expectedToBeEnabled: Bool
    var expectedVariables: [VariableKey: VariableValue]?

    init(
        description: String,
        environment: Environment,
        at: Double,
        context: [AttributeKey: AttributeValue]? = nil,
        expectedToBeEnabled: Bool,
        expectedVariables: [VariableKey: VariableValue]? = nil
    ) {
        self.description = description
        self.environment = environment
        self.at = at
        self.context = context
        self.expectedToBeEnabled = expectedToBeEnabled
        self.expectedVariables = expectedVariables
    }
}
