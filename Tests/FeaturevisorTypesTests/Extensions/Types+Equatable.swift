import FeaturevisorTypes

extension Condition: Equatable {
    public static func == (lhs: Condition, rhs: Condition) -> Bool {
        switch (lhs, rhs) {
            case (.plain(let lhsPlain), .plain(let rhsPlain)):
                return lhsPlain.value == rhsPlain.value
                    && lhsPlain.attribute == rhsPlain.attribute
                    && lhsPlain.operator == rhsPlain.operator
            case (.multiple(let lhsMultiple), .multiple(let rhsMultiple)):
                return lhsMultiple == rhsMultiple
            case (.and(let lhsAnd), .and(let rhsAnd)):
                return lhsAnd.and == rhsAnd.and
            case (.or(let lhsOr), .or(let rhsOr)):
                return lhsOr.or == rhsOr.or
            case (.not(let lhsNot), .not(let rhsNot)):
                return lhsNot.not == rhsNot.not
            default:
                return false
        }
    }
}

extension ConditionValue: Equatable {
    public static func == (lhs: ConditionValue, rhs: ConditionValue) -> Bool {
        switch (lhs, rhs) {
            case (.string(let lhsString), .string(let rhsString)):
                return lhsString == rhsString
            case (.integer(let lhsInteger), .integer(let rhsInteger)):
                return lhsInteger == rhsInteger
            case (.double(let lhsDouble), .double(let rhsDouble)):
                return lhsDouble == rhsDouble
            case (.boolean(let lhsBoolean), .boolean(let rhsBoolea)):
                return lhsBoolean == rhsBoolea
            case (.array(let lhsArray), .array(let rhsArray)):
                return lhsArray == rhsArray
            default:
                return false
        }
    }
}

extension BucketBy: Equatable {
    public static func == (lhs: BucketBy, rhs: BucketBy) -> Bool {
        switch (lhs, rhs) {
            case (.single(let lhsSingle), .single(let rhsSingle)):
                return lhsSingle == rhsSingle
            case (.and(let lhsAnd), .and(let rhsAnd)):
                return lhsAnd == rhsAnd
            case (.or(let lhsOr), .or(let rhsOr)):
                return lhsOr.or == rhsOr.or
            default:
                return false
        }
    }
}

extension GroupSegment: Equatable {
    public static func == (lhs: GroupSegment, rhs: GroupSegment) -> Bool {
        switch (lhs, rhs) {
            case (.plain(let lhsPlain), .plain(let rhsPlain)):
                return lhsPlain == rhsPlain
            case (.multiple(let lhsMultiple), .multiple(let rhsMultiple)):
                return lhsMultiple == rhsMultiple
            case (.and(let lhsAnd), .and(let rhsAnd)):
                return lhsAnd.and == rhsAnd.and
            case (.or(let lhsOr), .or(let rhsOr)):
                return lhsOr.or == rhsOr.or
            case (.not(let lhsNot), .not(let rhsNot)):
                return lhsNot.not == rhsNot.not
            default:
                return false
        }
    }
}

extension VariableValue: Equatable {
    public static func == (lhs: VariableValue, rhs: VariableValue) -> Bool {
        switch (lhs, rhs) {
            case (.string(let lhsString), .string(let rhsString)):
                return lhsString == rhsString
            case (.double(let lhsDouble), .double(let rhsDouble)):
                return lhsDouble == rhsDouble
            case (.integer(let lhsInteger), .integer(let rhsInteger)):
                return lhsInteger == rhsInteger
            case (.array(let lhsArray), .array(let rhsArray)):
                return lhsArray == rhsArray
            case (.object(let lhsObject), .object(let rhsObject)):
                return lhsObject == rhsObject
            case (.json(let lhsJson), .json(let rhsJson)):
                return lhsJson == rhsJson
            case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
                return lhsBoolean == rhsBoolean
            default:
                return false
        }
    }
}
