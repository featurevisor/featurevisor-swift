import FeaturevisorTypes
import Foundation

func parseDateFromString(dateString: String) -> Date? {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime]

    if let date = dateFormatter.date(from: dateString) {
        return date
    }
    else {
        return nil
    }
}

public func conditionIsMatched(condition: PlainCondition, context: Context) -> Bool {
    let attribute = condition.attribute
    let op = condition.operator
    let valueInCondition = condition.value
    let valueInAttributes = context[attribute]

    switch (valueInAttributes, valueInCondition) {
        // boolean, boolean
        case (.boolean(let valueInAttributes), .boolean(let valueInCondition)):
            switch op {
                case .equals:
                    return valueInAttributes == valueInCondition
                case .notEquals:
                    return valueInAttributes != valueInCondition
                default:
                    return false
            }

        // string, string
        case (.string(let valueInAttributes), .string(let valueInCondition)):
            if String(op.rawValue).starts(with: "semver") {

                let semverInAttributes = Semver(valueInAttributes)
                let semverInCondition = Semver(valueInCondition)

                switch op {
                    case .semverEquals:
                        return semverInAttributes == semverInCondition
                    case .semverNotEquals:
                        return semverInAttributes != semverInCondition
                    case .semverGreaterThan:
                        return semverInAttributes > semverInCondition
                    case .semverGreaterThanOrEquals:
                        return semverInAttributes >= semverInCondition
                    case .semverLessThan:
                        return semverInAttributes < semverInCondition
                    case .semverLessThanOrEquals:
                        return semverInAttributes <= semverInCondition
                    default:
                        return false
                }
            }

            switch op {
                case .equals:
                    return valueInAttributes == valueInCondition
                case .notEquals:
                    return valueInAttributes != valueInCondition
                case .contains:
                    return valueInAttributes.contains(valueInCondition)
                case .notContains:
                    return !valueInAttributes.contains(valueInCondition)
                case .startsWith:
                    return valueInAttributes.starts(with: valueInCondition)
                case .endsWith:
                    return valueInAttributes.hasSuffix(valueInCondition)
                case .before:
                    let dateInAttributes = parseDateFromString(dateString: valueInAttributes)
                    let dateInCondition = parseDateFromString(dateString: valueInCondition)

                    if let dateInAttributes = dateInAttributes,
                        let dateInCondition = dateInCondition
                    {
                        return dateInAttributes < dateInCondition
                    }

                    return false
                case .after:
                    let dateInAttributes = parseDateFromString(dateString: valueInAttributes)
                    let dateInCondition = parseDateFromString(dateString: valueInCondition)

                    if let dateInAttributes = dateInAttributes,
                        let dateInCondition = dateInCondition
                    {
                        return dateInAttributes > dateInCondition
                    }

                    return false
                default:
                    return false
            }

        // string, [strings]
        case (.string(let valueInAttribute), .array(let valuesInCondition)):
            switch op {
                case .in:
                    return valuesInCondition.contains(valueInAttribute)
                case .notIn:
                    return !valuesInCondition.contains(valueInAttribute)
                default:
                    return false
            }

        // date, string
        case (.date(let valueInAttributes), .string(let valueInCondition)):
            switch op {
                case .before:
                    let dateInAttributes = valueInAttributes
                    let dateInCondition = parseDateFromString(dateString: valueInCondition)

                    if let dateInCondition = dateInCondition {
                        return dateInAttributes < dateInCondition
                    }

                    return false
                case .after:
                    let dateInAttributes = valueInAttributes
                    let dateInCondition = parseDateFromString(dateString: valueInCondition)

                    if let dateInCondition = dateInCondition {
                        return dateInAttributes > dateInCondition
                    }

                    return false

                default:
                    return false
            }

        // integer, integer
        case (.integer(let valueInAttributes), .integer(let valueInCondition)):
            switch op {
                case .equals:
                    return valueInAttributes == valueInCondition
                case .notEquals:
                    return valueInAttributes != valueInCondition
                case .greaterThan:
                    return valueInAttributes > valueInCondition
                case .greaterThanOrEquals:
                    return valueInAttributes >= valueInCondition
                case .lessThan:
                    return valueInAttributes < valueInCondition
                case .lessThanOrEquals:
                    return valueInAttributes <= valueInCondition
                default:
                    return false
            }

        // double, double
        case (.double(let valueInAttributes), .double(let valueInCondition)):
            switch op {
                case .equals:
                    return valueInAttributes == valueInCondition
                case .notEquals:
                    return valueInAttributes != valueInCondition
                case .greaterThan:
                    return valueInAttributes > valueInCondition
                case .greaterThanOrEquals:
                    return valueInAttributes >= valueInCondition
                case .lessThan:
                    return valueInAttributes < valueInCondition
                case .lessThanOrEquals:
                    return valueInAttributes <= valueInCondition
                default:
                    return false
            }

        // default
        default:
            return false
    }
}

public func allConditionsAreMatched(condition: Condition, context: Context) -> Bool {
    switch condition {
        case .plain(let condition):
            return conditionIsMatched(condition: condition, context: context)

        case .multiple(let condition):
            return condition.allSatisfy { condition in
                allConditionsAreMatched(condition: condition, context: context)
            }

        case .and(let condition):
            return condition.and.allSatisfy { condition in
                allConditionsAreMatched(condition: condition, context: context)
            }

        case .or(let condition):
            return condition.or.contains { condition in
                allConditionsAreMatched(condition: condition, context: context)
            }

        case .not(let condition):
            return !condition.not.allSatisfy { condition in
                allConditionsAreMatched(condition: condition, context: context)
            }
    }
}
