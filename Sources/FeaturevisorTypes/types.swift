import Foundation

public typealias AttributeKey = String

public enum AttributeValue {
  case string(String)
  case integer(Int)
  case double(Double)
  case boolean(Bool)
  case date(Date)
  // @TODO: add `null` and `undefined` somehow
}
extension AttributeValue {
  public var stringValue: String {
    switch self {
      case .string(let value):
        return value
      case .integer(let value):
        return String(value)
      case .double(let value):
        return String(value)
      case .boolean(let value):
        return String(value)
      case .date(let value):
        return String(describing: value)
    }
  }
}

public typealias Context = [AttributeKey: AttributeValue]

public struct Attribute {
  public let key: AttributeKey
  public let type: String
  public let archived: Bool?  // only available in YAML

  public init(key: AttributeKey, type: String, archived: Bool?) {
    self.key = key
    self.type = type
    self.archived = archived
  }
}

public enum Operator: String {
  case equals = "equals"
  case notEquals = "notEquals"

  // numeric
  case greaterThan = "greaterThan"
  case greaterThanOrEquals = "greaterThanOrEquals"
  case lessThan = "lessThan"
  case lessThanOrEquals = "lessThanOrEquals"

  // string
  case contains = "contains"
  case notContains = "notContains"
  case startsWith = "startsWith"
  case endsWith = "endsWith"

  // semver (string)
  case semverEquals = "semverEquals"
  case semverNotEquals = "semverNotEquals"
  case semverGreaterThan = "semverGreaterThan"
  case semverGreaterThanOrEquals = "semverGreaterThanOrEquals"
  case semverLessThan = "semverLessThan"
  case semverLessThanOrEquals = "semverLessThanOrEquals"

  // date comparisons
  case before = "before"
  case after = "after"

  // array of strings
  case `in` = "in"
  case notIn = "notIn"
}

public enum ConditionValue {
  case string(String)
  case integer(Int)
  case double(Double)
  case boolean(Bool)
  case array([String])
  // @TODO: add Date type?
  // @TODO: add `null` and `undefined` somehow
}

public struct PlainCondition {
  public let attribute: AttributeKey
  public let `operator`: Operator
  public let value: ConditionValue
}

public struct AndCondition {
  public let and: [Condition]
}

public struct OrCondition {
  public let or: [Condition]
}

public struct NotCondition {
  public let not: [Condition]
}

public enum Condition {
  case plain(PlainCondition)
  case multiple([Condition])

  case and(AndCondition)
  case or(OrCondition)
  case not(NotCondition)
}

public typealias SegmentKey = String

public struct Segment {
  public let archived: Bool?
  public let key: SegmentKey
  public let conditions: Condition
}

public typealias PlainGroupSegment = SegmentKey

public struct AndGroupSegment {
  public let and: [GroupSegment]
}

public struct OrGroupSegment {
  public let or: [GroupSegment]
}

public struct NotGroupSegment {
  public let not: [GroupSegment]
}

public enum GroupSegment {
  case plain(PlainGroupSegment)
  case multiple([GroupSegment])

  case and(AndGroupSegment)
  case or(OrGroupSegment)
  case not(NotGroupSegment)
}

public typealias VariationValue = String

public typealias VariableKey = String

public enum VariableType: String {
  case boolean = "boolean"
  case string = "string"
  case integer = "integer"
  case double = "double"
  case array = "array"
  case object = "object"
  case json = "json"
}

public typealias VariableObjectValue = [String: VariableValue]

public enum VariableValue {
  case boolean(Bool)
  case string(String)
  case integer(Int)
  case double(Double)
  case array([VariableValue])
  case object(VariableObjectValue)
  case json(String)  // @TODO: check later if this is correct
  // @TODO: handle null and undefined later
}

public struct VariableOverride {
  public let value: VariableValue

  // one of the below must be present in YAML
  public let conditions: Condition?
  public let segments: GroupSegment?
}

public struct Variable {
  public let key: VariableKey
  public let value: VariableValue
  public let overrides: [VariableOverride]?
}

public struct Variation {
  public let description: String?  // ony available in YAML
  public let value: VariationValue
  public let weight: Weight?  // 0 to 100 (available from parsed YAML, but not in datafile)
  public let variables: [Variable]?
}

public struct VariableSchema {
  public let key: VariableKey
  public let type: VariableType
  public let defaultValue: VariableValue
}

public typealias FeatureKey = String

public typealias VariableValues = [VariableKey: VariableValue]

public struct Force {
  // one of the below must be present in YAML
  public let conditions: Condition?
  public let segments: GroupSegment?

  public let enabled: Bool?
  public let variation: VariationValue
  public let variables: VariableValues
}

public struct Slot {
  public let feature: FeatureKey?  // @TODO: allow false?
  public let percentage: Weight  // 0 to 100
}

public struct Group {
  public let key: String
  public let description: String
  public let slots: [Slot]
}

public typealias BucketKey = String

// 0 to 100,000
public typealias BucketValue = Int

///
/// Datafile-only types
///
// 0 to 100,000
public typealias Percentage = Int

public typealias Range = (start: Percentage, end: Percentage)

public struct Allocation {
  public let variation: VariationValue
  public let range: Range
}

public struct Traffic {
  public let key: RuleKey
  public let segments: GroupSegment
  public let percentage: Percentage

  public let enabled: Bool?
  public let variation: VariationValue?
  public let variables: VariableValues?

  public let allocation: [Allocation]
}

public typealias PlainBucketBy = String
public typealias AndBucketBy = [String]
public struct OrBucketBy {
  public let or: [String]
}

public enum BucketBy {
  case single(PlainBucketBy)
  case and(AndBucketBy)
  case or(OrBucketBy)
}

public struct Feature {
  public let key: FeatureKey
  public let variablesSchema: [VariableSchema]?
  public let variations: [Variation]
  public let bucketBy: BucketBy
  public let traffic: [Traffic]
  public let force: [Force]?
  public let ranges: [Range]?  // if in a Group (mutex), these are available slot ranges
}

public struct DatafileContent {
  public let schemaVersion: String
  public let revision: String
  public let attributes: [Attribute]
  public let segments: [Segment]
  public let features: [Feature]

  public init(
    schemaVersion: String,
    revision: String,
    attributes: [Attribute],
    segments: [Segment],
    features: [Feature]
  ) {
    self.schemaVersion = schemaVersion
    self.revision = revision
    self.attributes = attributes
    self.segments = segments
    self.features = features
  }
}

public struct OverrideFeature {
  public let enabled: Bool
  public let variation: VariationValue?
  public let variables: VariableValues?
}

public typealias OverrideFeatures = [FeatureKey: OverrideFeature]

public typealias StickyFeatures = OverrideFeatures

public typealias InitialFeatures = OverrideFeatures

///
/// YAML-only type
///
// 0 to 100
public typealias Weight = Double

public typealias EnvironmentKey = String

public typealias RuleKey = String

public struct Rule {
  public let key: RuleKey
  public let segments: GroupSegment
  public let percentage: Weight

  public let enabled: Bool?
  public let variation: VariationValue?
  public let variables: VariableValues?
}

public struct Environment {
  public let expose: Bool?
  public let rules: [Rule]
  public let force: [Force]?
}

public typealias Environments = [EnvironmentKey: Environment]

public struct ParsedFeature {
  public let key: FeatureKey

  public let archived: Bool
  public let description: String
  public let tags: [String]

  public let bucketBy: BucketBy

  public let variablesSchema: [VariableSchema]
  public let variations: [Variation]

  public let environments: Environments
}

///
/// Tests
///
public struct FeatureAssertion {
  public let description: String?
  public let at: Weight
  public let context: Context
  public let expectedToBeEnabled: Bool
  public let expectedVariation: VariationValue?
  public let expectedVariables: VariableValues?
}

public struct TestFeature {
  public let key: FeatureKey
  public let assertions: [FeatureAssertion]
}

public struct SegmentAssertion {
  public let description: String?
  public let context: Context
  public let expected: Bool
}

public struct TestSegment {
  public let key: SegmentKey
  public let assertions: [SegmentAssertion]
}

public struct Test {
  public let description: String?

  // needed for feature testing
  public let tag: String?
  public let environment: EnvironmentKey?
  public let features: [TestFeature]?

  // needed for segment testing
  public let segments: [TestSegment]?
}

public struct Spec {
  public let tests: [Test]
}
