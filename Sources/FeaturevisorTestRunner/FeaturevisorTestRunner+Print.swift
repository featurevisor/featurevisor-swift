import FeaturevisorTypes
import Foundation

extension FeaturevisorTestRunner {

    enum ResultMark: String {
        case success = "✔"
        case failure = "✘"

        init(result: Bool) {
            self = result ? .success : .failure
        }

        var mark: String {
            return rawValue
        }
    }

    func printAssertionResult(
        environment: Environment,
        index: Int,
        feature: String,
        assertionResult: Bool,
        expectedValueFailures: [VariableKey: (expected: VariableValue, got: VariableValue?)],
        description: String,
        onlyFailures: Bool
    ) {

        guard onlyFailures && !assertionResult || !onlyFailures else {
            return
        }

        print("\nTesting: \(feature).feature.yml")
        print(" feature \"\(feature)\"")

        let resultMark = ResultMark(result: assertionResult)

        print(" \(resultMark.mark) Assertion #\(index): \(environment.rawValue) \(description)")

        expectedValueFailures.forEach({ (key, value) in
            print("   => variable key: \(key)")
            print("          => expected: \(value.expected)")
            if let got = value.got {
                print("          => received: \(got)")
            }
            else {
                print("          => received: nil")
            }
        })
    }
}
