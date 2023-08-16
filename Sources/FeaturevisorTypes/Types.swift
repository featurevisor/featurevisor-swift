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

public struct Attribute: Decodable {
    public let key: AttributeKey
    public let type: String
    public let archived: Bool?  // only available in YAML
    public let capture: Bool?

    public init(key: AttributeKey, type: String, archived: Bool?, capture: Bool?) {
        self.key = key
        self.type = type
        self.archived = archived
        self.capture = capture
    }
}

public enum Operator: String, Decodable {
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

public enum ConditionValue: Decodable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case array([String])
    // @TODO: add Date type?
    // @TODO: add `null` and `undefined` somehow
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(ConditionValue.self) unknown")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

public struct PlainCondition: Decodable {
    public let attribute: AttributeKey
    public let `operator`: Operator
    public let value: ConditionValue
}

public struct AndCondition: Decodable {
    public let and: [Condition]
}

public struct OrCondition: Decodable {
    public let or: [Condition]
}

public struct NotCondition: Decodable {
    public let not: [Condition]
}

public enum Condition: Decodable {
    case plain(PlainCondition)
    case multiple([Condition])

    case and(AndCondition)
    case or(OrCondition)
    case not(NotCondition)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
      
        if let plainCondition = try? container.decode(PlainCondition.self) {
            self = .plain(plainCondition)
        } else if let multipleCondition = try? container.decode([Condition].self) {
            self = .multiple(multipleCondition)
        } else if let andCondition = try? container.decode(AndCondition.self) {
            self = .and(andCondition)
        } else if let orCondition = try? container.decode(OrCondition.self) {
            self = .or(orCondition)
        } else if let notCondition = try? container.decode(NotCondition.self) {
            self = .not(notCondition)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(Condition.self) unknown")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

public typealias SegmentKey = String

public struct Segment: Decodable {
    public let archived: Bool?
    public let key: SegmentKey
    public let conditions: Condition
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        archived = try? container.decode(Bool.self, forKey: .archived)
        key = try container.decode(SegmentKey.self, forKey: .key)
        
        let conditionsString = try container.decode(String.self, forKey: .conditions)
        let jsonDecoder = JSONDecoder()
        conditions = try jsonDecoder.decode(Condition.self, from: conditionsString.data(using: .utf8)!)
    }
    
    public enum CodingKeys: String, CodingKey {
        case archived
        case key
        case conditions
    }
}

public typealias PlainGroupSegment = SegmentKey

public struct AndGroupSegment: Decodable {
    public let and: [GroupSegment]
}

public struct OrGroupSegment: Decodable {
    public let or: [GroupSegment]
}

public struct NotGroupSegment: Decodable {
    public let not: [GroupSegment]
}

public enum GroupSegment: Decodable {
    case plain(PlainGroupSegment)
    case multiple([GroupSegment])

    case and(AndGroupSegment)
    case or(OrGroupSegment)
    case not(NotGroupSegment)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
      
        if let plainCondition = try? container.decode(PlainGroupSegment.self) {
            self = .plain(plainCondition)
        } else if let multipleCondition = try? container.decode([GroupSegment].self) {
            self = .multiple(multipleCondition)
        } else if let andCondition = try? container.decode(AndGroupSegment.self) {
            self = .and(andCondition)
        } else if let orCondition = try? container.decode(OrGroupSegment.self) {
            self = .or(orCondition)
        } else if let notCondition = try? container.decode(NotGroupSegment.self) {
            self = .not(notCondition)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(GroupSegment.self) unknown")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

public typealias VariationValue = String

public typealias VariableKey = String

public enum VariableType: String, Decodable {
    case boolean = "boolean"
    case string = "string"
    case integer = "integer"
    case double = "double"
    case array = "array"
    case object = "object"
    case json = "json"
}

public typealias VariableObjectValue = [String: VariableValue]

public enum VariableValue: Decodable {
    case boolean(Bool)
    case string(String)
    case integer(Int)
    case double(Double)
    case array([VariableValue])
    case object(VariableObjectValue)
    case json(String)  // @TODO: check later if this is correct
    // @TODO: handle null and undefined later
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            // @TODO: Deal with json case too
            self = .string(string)
        } else if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        } else if let array = try? container.decode([VariableValue].self) {
            self = .array(array)
        } else if let object = try? container.decode(VariableObjectValue.self) {
            self = .object(object)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(VariableValue.self) unknown")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

public struct VariableOverride: Decodable {
    public let value: VariableValue

    // one of the below must be present in YAML
    public let conditions: Condition?
    public let segments: GroupSegment?
}

public struct Variable: Decodable {
    public let key: VariableKey
    public let value: VariableValue
    public let overrides: [VariableOverride]?
}

public struct Variation: Decodable {
    public let description: String?  // ony available in YAML
    public let value: VariationValue
    public let weight: Weight?  // 0 to 100 (available from parsed YAML, but not in datafile)
    public let variables: [Variable]?
}

public struct VariableSchema: Decodable {
    public let key: VariableKey
    public let type: VariableType
    public let defaultValue: VariableValue
}

public typealias FeatureKey = String

public typealias VariableValues = [VariableKey: VariableValue]

public struct Force: Decodable {
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

public struct Range: Decodable {
    public let start: Percentage
    public let end: Percentage
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let range = try container.decode([Percentage].self)
        self.start = range[0]
        self.end = range[1]
    }
}

public struct Allocation: Decodable {
    public let variation: VariationValue
    public let range: Range
}

public struct Traffic: Decodable {
    public let key: RuleKey
    public let segments: GroupSegment
    public let percentage: Percentage

    public let enabled: Bool?
    public let variation: VariationValue?
    public let variables: VariableValues? // @TODO Tuple typealias is not managed by Decodable

    public let allocation: [Allocation]
}

public typealias PlainBucketBy = String
public typealias AndBucketBy = [String]
public struct OrBucketBy: Decodable {
    public let or: [String]
    
    public init(or: [String]) {
        self.or = or
    }
}

public enum BucketBy: Decodable {
    case single(PlainBucketBy)
    case and(AndBucketBy)
    case or(OrBucketBy)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let single = try? container.decode(PlainBucketBy.self) {
            self = .single(single)
        } else if let ands = try? container.decode(AndBucketBy.self) {
            self = .and(ands)
        } else if let ors = try? container.decode(OrBucketBy.self) {
            self = .or(ors)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(BucketBy.self) unknown")
            throw DecodingError.dataCorrupted(context)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case single
        case and
        case or
    }
}

public struct RequiredWithVariation: Decodable {
    public let key: FeatureKey
    public let variation: VariationValue
}

public enum Required: Decodable {
    case featureKey(FeatureKey)
    case withVariation(RequiredWithVariation)
}

public struct Feature: Decodable {
    public let key: FeatureKey
    public let deprecated: Bool?
    public let variablesSchema: [VariableSchema]
    public let variations: [Variation]
    public let bucketBy: BucketBy
    public let required: [Required]
    public let traffic: [Traffic]
    public let force: [Force]
    public let ranges: [Range]  // if in a Group (mutex), these are available slot ranges
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(FeatureKey.self, forKey: .key)
        deprecated = try? container.decode(Bool.self, forKey: .deprecated)
        variablesSchema = (try? container.decode([VariableSchema].self, forKey: .variablesSchema)) ?? []
        variations = (try? container.decode([Variation].self, forKey: .variations)) ?? []
        bucketBy = try container.decode(BucketBy.self, forKey: .bucketBy)
        required = (try? container.decode([Required].self, forKey: .required)) ?? []
        traffic = (try? container.decode([Traffic].self, forKey: .traffic)) ?? []
        force = (try? container.decode([Force].self, forKey: .force)) ?? []
        ranges = (try? container.decode([Range].self, forKey: .ranges)) ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case key
        case deprecated
        case variablesSchema
        case variations
        case bucketBy
        case required
        case traffic
        case force
        case ranges
    }
}

public struct DatafileContent: Decodable {
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
    
    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)

        schemaVersion = try values.decode(String.self, forKey: .schemaVersion)
        revision = try values.decode(String.self, forKey: .revision)
        attributes = try values.decode([Attribute].self, forKey: .attributes)
        segments = try values.decode([Segment].self, forKey: .segments)
        features = try values.decode([Feature].self, forKey: .features)
    }
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case revision
        case attributes
        case segments
        case features
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

    public let archived: Bool?
    public let deprecated: Bool?

    public let description: String
    public let tags: [String]

    public let bucketBy: BucketBy

    public let required: [Required]?

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
    public let expectedToMatch: Bool
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
