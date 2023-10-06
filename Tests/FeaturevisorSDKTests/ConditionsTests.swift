import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

class ConditionsTests: XCTestCase {

    func testBooleanEquals() {
        let condition = PlainCondition(
            attribute: "isTrue",
            operator: .equals,
            value: .boolean(true)
        )
        var context = Context()
        context["isTrue"] = .boolean(true)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testBooleanNotEquals() {
        let condition = PlainCondition(
            attribute: "isTrue",
            operator: .notEquals,
            value: .boolean(true)
        )
        var context = Context()
        context["isTrue"] = .boolean(false)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringEquals() {
        let condition = PlainCondition(attribute: "name", operator: .equals, value: .string("John"))
        var context = Context()
        context["name"] = .string("John")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringNotEquals() {
        let condition = PlainCondition(
            attribute: "name",
            operator: .notEquals,
            value: .string("John")
        )
        var context = Context()
        context["name"] = .string("Jane")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringContains() {
        let condition = PlainCondition(
            attribute: "text",
            operator: .contains,
            value: .string("world")
        )
        var context = Context()
        context["text"] = .string("Hello, world!")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringNotContains() {
        let condition = PlainCondition(
            attribute: "text",
            operator: .notContains,
            value: .string("test")
        )
        var context = Context()
        context["text"] = .string("wrongText")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDateBefore() {
        let condition = PlainCondition(
            attribute: "date",
            operator: .before,
            value: .string("2023-10-07T00:00:00Z")
        )
        var context = Context()
        context["date"] = .string("2023-10-06T00:00:00Z")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDateAfter() {
        let condition = PlainCondition(
            attribute: "date",
            operator: .after,
            value: .string("2023-10-05T00:00:00Z")
        )
        var context = Context()
        context["date"] = .string("2023-10-06T00:00:00Z")

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerEquals() {
        let condition = PlainCondition(attribute: "age", operator: .equals, value: .integer(30))
        var context = Context()
        context["age"] = .integer(30)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerNotEquals() {
        let condition = PlainCondition(attribute: "age", operator: .notEquals, value: .integer(25))
        var context = Context()
        context["age"] = .integer(30)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerGreaterThan() {
        let condition = PlainCondition(
            attribute: "age",
            operator: .greaterThan,
            value: .integer(25)
        )
        var context = Context()
        context["age"] = .integer(30)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleEquals() {
        let condition = PlainCondition(attribute: "price", operator: .equals, value: .double(19.99))
        var context = Context()
        context["price"] = .double(19.99)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleNotEquals() {
        let condition = PlainCondition(
            attribute: "price",
            operator: .notEquals,
            value: .double(25.0)
        )
        var context = Context()
        context["price"] = .double(19.99)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleLessThanOrEqual() {
        let condition = PlainCondition(
            attribute: "price",
            operator: .lessThanOrEquals,
            value: .double(19.99)
        )
        var context = Context()
        context["price"] = .double(19.99)

        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testSemverEquality() {
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.3")

        XCTAssertEqual(semver1, semver2)
    }

    func testSemverInequality() {
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.4")

        XCTAssertNotEqual(semver1, semver2)
    }

    func testSemverGreaterThan() {
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("1.9.9")

        XCTAssertTrue(semver1 > semver2)
    }

    func testSemverGreaterThanOrEqual() {
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("2.0.0")

        XCTAssertTrue(semver1 >= semver2)
    }

    func testSemverLessThan() {
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.1")

        XCTAssertTrue(semver1 < semver2)
    }

    func testSemverLessThanOrEqual() {
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.0")

        XCTAssertTrue(semver1 <= semver2)
    }

    func testSemverParsing() {
        let semver = Semver("3.2.1")

        XCTAssertEqual(semver.major, 3)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 1)
    }

    func testSemverParsingInvalidVersion() {
        let semver = Semver("invalid")

        XCTAssertEqual(semver.major, 0)
        XCTAssertEqual(semver.minor, 0)
        XCTAssertEqual(semver.patch, 0)
    }
}
