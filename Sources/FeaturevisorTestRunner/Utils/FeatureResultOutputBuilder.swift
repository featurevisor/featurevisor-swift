import FeaturevisorTypes
import Foundation

class FeatureResultOutputBuilder {

    enum ResultMark: String {
        case success = "✔"
        case failure = "✘"

        init(result: Bool) {
            self = result ? .success : .failure
        }
    }

    struct Assertion {
        let environment: Environment
        let index: Int
        let assertionResult: Bool
        let expectedValueFailures: [VariableKey: (expected: VariableValue, got: VariableValue?)]
        let description: String
        let elapsedTime: UInt64
    }

    private let onlyFailures: Bool
    private let feature: String
    private var assertions: [Assertion] = []

    init(feature: String, onlyFailures: Bool) {
        self.onlyFailures = onlyFailures
        self.feature = feature
    }

    @discardableResult func addAssertion(
        environment: Environment,
        index: Int,
        assertionResult: Bool,
        expectedValueFailures: [VariableKey: (expected: VariableValue, got: VariableValue?)],
        description: String,
        elapsedTime: UInt64
    ) -> Self {
        let assertion: Assertion = .init(
            environment: environment,
            index: index,
            assertionResult: assertionResult,
            expectedValueFailures: expectedValueFailures,
            description: description,
            elapsedTime: elapsedTime
        )

        assertions.append(assertion)
        return self
    }

    func build() -> String? {

        let hasFailedAssertions = !assertions.filter({ !$0.assertionResult }).isEmpty

        guard onlyFailures && hasFailedAssertions || !onlyFailures else {
            return nil
        }

        let totallElapsedTimeInMilliSeconds = assertions.reduce(
            0.0,
            { $0 + $1.elapsedTime.miliseconds }
        )
        var output: String = ""

        output.append("\nTesting: \(feature).feature.yml (\(totallElapsedTimeInMilliSeconds)ms)")
        output.append("\n feature \"\(feature)\"")

        assertions.forEach({ assertion in

            let mark = ResultMark(result: assertion.assertionResult)
            let index = assertion.index
            let env = assertion.environment.rawValue
            let description = assertion.description
            let expectedValueFailures = assertion.expectedValueFailures
            let elapsedTimeInMilliSeconds = assertion.elapsedTime.miliseconds

            output.append(
                "\n \(mark.rawValue) Assertion #\(index): \(env) \(description) (\(elapsedTimeInMilliSeconds)ms)"
            )

            expectedValueFailures.forEach({ (key, value) in
                output.append("\n   => variable key: \(key)")
                output.append("\n          => expected: \(value.expected)")

                if let got = value.got {
                    output.append("\n          => received: \(got)")
                }
                else {
                    output.append("\n          => received: nil")
                }
            })
        })

        return output
    }
}
