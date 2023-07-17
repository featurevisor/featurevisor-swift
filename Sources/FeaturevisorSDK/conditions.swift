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

public func conditionIsMatched(condition: PlainCondition, attributes: Attributes) -> Bool {
  let attribute = condition.attribute
  let op = condition.operator
  let valueInCondition = condition.value
  let valueInAttributes = attributes[attribute]

  switch (valueInAttributes, valueInCondition) {
    // boolean, boolean
    case let (.boolean(valueInAttributes), .boolean(valueInCondition)):
      switch op {
        case .equals:
          return valueInAttributes == valueInCondition
        case .notEquals:
          return valueInAttributes != valueInCondition
        default:
          return false
      }

    // string, string
    case let (.string(valueInAttributes), .string(valueInCondition)):
      if String(op.rawValue).starts(with: "semver") {
        // @TODO: handle semver comparisons here

        // let semverInAttributes = Semver(valueInAttributes)
        // let semverInCondition = Semver(valueInCondition)

        // switch op {
        //   case .semverEquals:
        //     return semverInAttributes == semverInCondition
        //   case .semverNotEquals:
        //     return semverInAttributes != semverInCondition
        //   case .semverGreaterThan:
        //     return semverInAttributes > semverInCondition
        //   case .semverGreaterThanOrEquals:
        //     return semverInAttributes >= semverInCondition
        //   case .semverLessThan:
        //     return semverInAttributes < semverInCondition
        //   case .semverLessThanOrEquals:
        //     return semverInAttributes <= semverInCondition
        //   default:
        //     return false
        // }

        return false
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

          if let dateInAttributes = dateInAttributes, let dateInCondition = dateInCondition {
            return dateInAttributes < dateInCondition
          }

          return false
        case .after:
          let dateInAttributes = parseDateFromString(dateString: valueInAttributes)
          let dateInCondition = parseDateFromString(dateString: valueInCondition)

          if let dateInAttributes = dateInAttributes, let dateInCondition = dateInCondition {
            return dateInAttributes > dateInCondition
          }

          return false
        default:
          return false
      }

    // date, string
    case let (.date(valueInAttributes), .string(valueInCondition)):
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
    case let (.integer(valueInAttributes), .integer(valueInCondition)):
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
    case let (.double(valueInAttributes), .double(valueInCondition)):
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

public func allConditionsAreMatched(condition: Condition, attributes: Attributes) -> Bool {
  switch condition {
    case let .plain(condition):
      return conditionIsMatched(condition: condition, attributes: attributes)

    case let .multiple(condition):
      return condition.allSatisfy { condition in
        allConditionsAreMatched(condition: condition, attributes: attributes)
      }

    case let .and(condition):
      return condition.and.allSatisfy { condition in
        allConditionsAreMatched(condition: condition, attributes: attributes)
      }

    case let .or(condition):
      return condition.or.contains { condition in
        allConditionsAreMatched(condition: condition, attributes: attributes)
      }

    case let .not(condition):
      return !condition.not.allSatisfy { condition in
        allConditionsAreMatched(condition: condition, attributes: attributes)
      }
  }
}
