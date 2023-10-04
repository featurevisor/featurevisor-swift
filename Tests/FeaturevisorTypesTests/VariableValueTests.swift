import Foundation
import XCTest

@testable import FeaturevisorTypes

final class VariableValueTests: XCTestCase {

    func testValueAsBoolean() {

        // GIVEN
        let variable: VariableValue = .boolean(true)

        // WHEN
        let value = variable.value as! Bool

        // THEN
        XCTAssertTrue(value)
    }

    func testValueAsString() {

        // GIVEN
        let variable: VariableValue = .string("Featurevisor rocks")

        // WHEN
        let value = variable.value as! String

        // THEN
        XCTAssertEqual(value, "Featurevisor rocks")
    }

    func testValueAsDouble() {

        // GIVEN
        let variable: VariableValue = .double(111.11)

        // WHEN
        let value = variable.value as! Double

        // THEN
        XCTAssertEqual(value, 111.11)
    }

    func testValueAsInteger() {

        // GIVEN
        let variable: VariableValue = .integer(111)

        // WHEN
        let value = variable.value as! Int

        // THEN
        XCTAssertEqual(value, 111)
    }

    func testValueAsJson() {

        // GIVEN
        let variable: VariableValue = .json("{\title\":\"Awesome!\"]")

        // WHEN
        let value = variable.value as! String

        // THEN
        XCTAssertEqual(value, "{\title\":\"Awesome!\"]")
    }

    func testValueAsArray() {

        // GIVEN
        let variable: VariableValue = .array(["item1", "item2"])

        // WHEN
        let value = variable.value as! [String]

        // THEN
        XCTAssertEqual(value, ["item1", "item2"])
    }

    func testValueAsObject() {

        // GIVEN
        let variable: VariableValue = .object(["title": .string("Featurevisor is so cool")])

        // WHEN
        let value = variable.value as! VariableObjectValue

        // THEN
        XCTAssertEqual(value, ["title": .string("Featurevisor is so cool")])
    }
}
