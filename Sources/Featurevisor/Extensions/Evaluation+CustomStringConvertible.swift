import FeaturevisorSDK

extension Evaluation: EvaluationStringConvertible {}

private protocol EvaluationStringConvertible: CustomStringConvertible {}

extension EvaluationStringConvertible {

    public var description: String {
        let ignoreKeys = [
            "featureKey", "variableKey", "variation", "variableSchema", "traffic", "force",
        ]

        let mirror = Mirror(reflecting: self)

        let output: [String] = mirror
            .allChildren
            .sorted {
                $0.label ?? "" < $1.label ?? ""
            }
            .compactMap { (key: String?, value: Any) in
                guard let key, !ignoreKeys.contains(key) else {
                    return nil
                }

                switch value {
                    case Optional<Any>.none:
                        return nil
                    case Optional<Any>.some(let wrapped):
                        return "- \(key): \(wrapped)"
                    default:
                        return nil
                }
            }

        return "\(output.joined(separator: "\n"))"
    }
}

extension Mirror {

    /// The children of the mirror and its superclasses.
    fileprivate var allChildren: [Mirror.Child] {
        var children = Array(self.children)

        var superclassMirror = self.superclassMirror

        while let mirror = superclassMirror {
            children.append(contentsOf: mirror.children)
            superclassMirror = mirror.superclassMirror
        }

        return children
    }
}
