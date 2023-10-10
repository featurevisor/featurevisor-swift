import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

class ConditionsTests: XCTestCase {

    func testBooleanEquals() {

        //Given
        let condition = PlainCondition(
            attribute: "isTrue",
            operator: .equals,
            value: .boolean(true)
        )
        var context = Context()

        //When
        context["isTrue"] = .boolean(true)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testBooleanNotEquals() {

        //Given
        let condition = PlainCondition(
            attribute: "isTrue",
            operator: .notEquals,
            value: .boolean(true)
        )
        var context = Context()

        //When
        context["isTrue"] = .boolean(false)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringEquals() {

        //Given
        let condition = PlainCondition(attribute: "name", operator: .equals, value: .string("John"))
        var context = Context()

        //When
        context["name"] = .string("John")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringNotEquals() {

        //Given
        let condition = PlainCondition(
            attribute: "name",
            operator: .notEquals,
            value: .string("John")
        )
        var context = Context()

        //When
        context["name"] = .string("Jane")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringContains() {

        //Given
        let condition = PlainCondition(
            attribute: "text",
            operator: .contains,
            value: .string("world")
        )
        var context = Context()

        //When
        context["text"] = .string("Hello, world!")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testStringNotContains() {

        //Given
        let condition = PlainCondition(
            attribute: "text",
            operator: .notContains,
            value: .string("test")
        )
        var context = Context()

        //When
        context["text"] = .string("wrongText")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDateBefore() {

        //Given
        let condition = PlainCondition(
            attribute: "date",
            operator: .before,
            value: .string("2023-10-07T00:00:00Z")
        )
        var context = Context()

        //When
        context["date"] = .string("2023-10-06T00:00:00Z")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDateAfter() {

        //Given
        let condition = PlainCondition(
            attribute: "date",
            operator: .after,
            value: .string("2023-10-05T00:00:00Z")
        )
        var context = Context()

        //When
        context["date"] = .string("2023-10-06T00:00:00Z")

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerEquals() {

        //Given
        let condition = PlainCondition(attribute: "age", operator: .equals, value: .integer(30))
        var context = Context()

        //When
        context["age"] = .integer(30)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerNotEquals() {

        //Given
        let condition = PlainCondition(attribute: "age", operator: .notEquals, value: .integer(25))
        var context = Context()

        //When
        context["age"] = .integer(30)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testIntegerGreaterThan() {

        //Given
        let condition = PlainCondition(
            attribute: "age",
            operator: .greaterThan,
            value: .integer(25)
        )
        var context = Context()

        //When
        context["age"] = .integer(30)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleEquals() {

        //Given
        let condition = PlainCondition(attribute: "price", operator: .equals, value: .double(19.99))
        var context = Context()

        //When
        context["price"] = .double(19.99)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleNotEquals() {

        //Given
        let condition = PlainCondition(
            attribute: "price",
            operator: .notEquals,
            value: .double(25.0)
        )
        var context = Context()

        //When
        context["price"] = .double(19.99)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testDoubleLessThanOrEqual() {

        //Given
        let condition = PlainCondition(
            attribute: "price",
            operator: .lessThanOrEquals,
            value: .double(19.99)
        )
        var context = Context()

        //When
        context["price"] = .double(19.99)

        //Then
        XCTAssertTrue(conditionIsMatched(condition: condition, context: context))
    }

    func testAllConditionsAreMatchedPlain() {

        //Given
        let condition = Condition.plain(
            PlainCondition(attribute: "name", operator: .equals, value: .string("John"))
        )
        var context = Context()

        //When
        context["name"] = .string("John")

        //Then
        XCTAssertTrue(allConditionsAreMatched(condition: condition, context: context))
    }

    func testAllConditionsAreMatchedMultiple() {

        //Given
        let conditions: [Condition] = [
            .plain(PlainCondition(attribute: "age", operator: .greaterThan, value: .integer(25))),
            .plain(PlainCondition(attribute: "name", operator: .equals, value: .string("John"))),
        ]
        var context = Context()

        //When
        context["age"] = .integer(30)
        context["name"] = .string("John")

        //Then
        XCTAssertTrue(allConditionsAreMatched(condition: .multiple(conditions), context: context))
    }

    func testAllConditionsAreMatchedAnd() {

        //Given
        let conditions: [Condition] = [
            .plain(PlainCondition(attribute: "age", operator: .greaterThan, value: .integer(25))),
            .plain(PlainCondition(attribute: "name", operator: .equals, value: .string("John"))),
        ]
        var context = Context()

        //When
        context["age"] = .integer(30)
        context["name"] = .string("John")

        //Then
        XCTAssertTrue(
            allConditionsAreMatched(
                condition: .and(AndCondition(and: conditions)),
                context: context
            )
        )
    }

    func testAllConditionsAreMatchedOr() {

        //Given
        let conditions: [Condition] = [
            .plain(PlainCondition(attribute: "age", operator: .greaterThan, value: .integer(25))),
            .plain(PlainCondition(attribute: "name", operator: .equals, value: .string("John"))),
        ]
        var context = Context()

        //When
        context["age"] = .integer(30)
        context["name"] = .string("Jane")

        //Then
        XCTAssertTrue(
            allConditionsAreMatched(condition: .or(OrCondition(or: conditions)), context: context)
        )
    }

    func testAllConditionsAreMatchedNot() {

        //Given
        let conditions: [Condition] = [
            .plain(PlainCondition(attribute: "age", operator: .greaterThan, value: .integer(25))),
            .plain(PlainCondition(attribute: "name", operator: .equals, value: .string("John"))),
        ]
        var context = Context()

        //When
        context["age"] = .integer(30)
        context["name"] = .string("Jane")

        //Then
        XCTAssertTrue(
            allConditionsAreMatched(
                condition: .not(NotCondition(not: conditions)),
                context: context
            )
        )
    }
}
