import Foundation

enum AssertionMapper {

    static func map(from assertions: [FeatureTestAssertionFile]) -> [Assertion] {
        var outcome: [Assertion] = []

        assertions.forEach({ assertion in

            guard let matrix = assertion.matrix else {
                outcome.append(assertion.asAssertion())
                return
            }

            var combinationPairs: [[(String, String)]] = []

            matrix.forEach({ (key: String, values: [String]) in
                let newValues: [(String, String)] = values.map({
                    (key, $0)
                })

                combinationPairs.append(newValues)
            })

            let xxx = Combinations.combine(lists: combinationPairs)

            xxx.forEach({ values in

                var description = assertion.description
                var at = "\(assertion.at)"
                var context = assertion.context ?? [:]
                var environment = assertion.environment

                values.forEach({ pair in
                    let key = pair.0
                    let value = pair.1

                    description = replace(source: description, key: key, value: value)
                    environment = replace(source: environment, key: key, value: value)
                    at = replace(source: at, key: key, value: value)

                    for (contextKey, contextValue) in context {
                        switch contextValue {
                            case .string(let _value):
                                let updatedValue = replace(source: _value, key: key, value: value)
                                context.updateValue(.string(updatedValue), forKey: contextKey)
                            default:
                                break
                        }
                    }
                })

                let _assertion = Assertion(
                    description: description,
                    environment: Environment(rawValue: environment)!,  // TODO
                    at: Double(at)!,  // TODO
                    context: context,
                    expectedToBeEnabled: assertion.expectedToBeEnabled,
                    expectedVariables: VariableValueMapper.map(from: assertion.expectedVariables)
                )

                outcome.append(_assertion)
            })
        })

        return outcome
    }
}

extension AssertionMapper {

    fileprivate static func replace(source: String, key: String, value: String) -> String {
        return source.replacingOccurrences(of: "${{ \(key) }}", with: value)
    }
}
