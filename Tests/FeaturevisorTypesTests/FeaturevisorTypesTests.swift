import Foundation
import XCTest

@testable import FeaturevisorTypes

final class FeaturevisorTypesTests: XCTestCase {
    
    func testDecodeReturnsValidDatafileContentObjectForValidDatafileContentJSONResponse() throws {
        
        // GIVEN
        let path = Bundle.module.url(forResource: "DatafileContentValidResponse", withExtension: "json")!
        
        // WHEN
        let json = try Data(contentsOf: path)
        let result = try JSONDecoder().decode(DatafileContent.self, from: json)
        
        // THEN
        XCTAssertEqual(result.revision, "0.0.13")
        XCTAssertEqual(result.schemaVersion, "1")
        XCTAssertEqual(result.attributes.count, 3)
        XCTAssertEqual(result.features.count, 2)
        XCTAssertEqual(result.segments.count, 1)
        
        let segment = result.segments[0]
        XCTAssertEqual(segment.key, "myAccount")
        XCTAssertNil(segment.archived)
        XCTAssertEqual(segment.conditions, .multiple([
            .plain(PlainCondition(attribute: "chapter", operator: .equals, value: .string("account")))]))
        
        let feature1 = result.features[0]
        XCTAssertEqual(feature1.key, "e_bar")
        XCTAssertNil(feature1.deprecated)
        XCTAssertEqual(feature1.bucketBy, .single("userId"))
        XCTAssertEqual(feature1.ranges.count, 0)
        XCTAssertEqual(feature1.variablesSchema.count, 2)
        XCTAssertEqual(feature1.variations.count, 3)
        XCTAssertEqual(feature1.traffic.count, 2)
        XCTAssertEqual(feature1.force.count, 1)

        let variation1_1 = feature1.variations[0]
        XCTAssertEqual(variation1_1.value, "control")
        XCTAssertNil(variation1_1.description)
        XCTAssertEqual(variation1_1.weight, 33.34)
        XCTAssertEqual(variation1_1.variables!.count, 1)

        let variable1_1 = variation1_1.variables![0]
        XCTAssertEqual(variable1_1.key, "hero")
        XCTAssertEqual(variable1_1.value, .object([
            "title": .string("Hero Title for B"),
            "subtitle": .string("Hero Subtitle for B"),
            "alignment": .string("center for B")]))
        XCTAssertEqual(variable1_1.overrides!.count, 1)

        let override1_1 = variable1_1.overrides![0]
        XCTAssertEqual(override1_1.value, .object([
            "title": .string("Hero Title for B in DE or CH"),
            "subtitle": .string("Hero Subtitle for B in DE of CH"),
            "alignment": .string("center for B in DE or CH")]))
        XCTAssertEqual(override1_1.segments, .or(
            OrGroupSegment(or: [.plain("germany"), .plain("switzerland")])))
        
        let variation1_2 = feature1.variations[1]
        XCTAssertEqual(variation1_2.value, "treatment")
        XCTAssertNil(variation1_2.description)
        XCTAssertEqual(variation1_2.weight, 33.33)
        XCTAssertNil(variation1_2.variables)
        
        let variation1_3 = feature1.variations[2]
        XCTAssertEqual(variation1_3.value, "anotherTreatment")
        XCTAssertNil(variation1_3.description)
        XCTAssertEqual(variation1_3.weight, 33.33)
        XCTAssertNil(variation1_3.variables)
        
        let traffic1_1 = feature1.traffic[0]
        XCTAssertEqual(traffic1_1.key, "1")
        XCTAssertNil(traffic1_1.enabled)
        XCTAssertEqual(traffic1_1.percentage, 100000)
        XCTAssertEqual(traffic1_1.variation, nil)
        XCTAssertEqual(traffic1_1.segments, .multiple([.plain("myAccount")]))
        XCTAssertNil(traffic1_1.variables)
        XCTAssertEqual(traffic1_1.allocation.count, 3)
        
        let allocation1_1 = traffic1_1.allocation[0]
        XCTAssertEqual(allocation1_1.variation, "control")
        XCTAssertEqual(allocation1_1.range.start, 0)
        XCTAssertEqual(allocation1_1.range.end, 33340)
        
        let allocation1_2 = traffic1_1.allocation[1]
        XCTAssertEqual(allocation1_2.variation, "treatment")
        XCTAssertEqual(allocation1_2.range.start, 33340)
        XCTAssertEqual(allocation1_2.range.end, 66670)
        
        let allocation1_3 = traffic1_1.allocation[2]
        XCTAssertEqual(allocation1_3.variation, "anotherTreatment")
        XCTAssertEqual(allocation1_3.range.start, 66670)
        XCTAssertEqual(allocation1_3.range.end, 100000)
        
        let traffic1_2 = feature1.traffic[1]
        XCTAssertEqual(traffic1_2.key, "2")
        XCTAssertNil(traffic1_2.enabled)
        XCTAssertEqual(traffic1_2.percentage, 0)
        XCTAssertEqual(traffic1_2.variation, nil)
        XCTAssertEqual(traffic1_2.segments, .plain("*"))
        XCTAssertNil(traffic1_2.variables)
        XCTAssertEqual(traffic1_2.allocation.count, 0)
        
        let variablesSchema1_1 = feature1.variablesSchema[0]
        XCTAssertEqual(variablesSchema1_1.key, "color")
        XCTAssertEqual(variablesSchema1_1.type, .string)
        XCTAssertEqual(variablesSchema1_1.defaultValue, .string("red"))

        let variablesSchema1_2 = feature1.variablesSchema[1]
        XCTAssertEqual(variablesSchema1_2.key, "hero")
        XCTAssertEqual(variablesSchema1_2.type, .object)
        XCTAssertEqual(variablesSchema1_2.defaultValue, .object([
                                      "title": .string("Hero Title"),
                                      "subtitle": .string("Hero Subtitle"),
                                      "alignment": .string("center")]))

        let force1_1 = feature1.force[0]
        XCTAssertTrue(force1_1.enabled!)
        XCTAssertEqual(force1_1.conditions, .and(AndCondition(and: [
            .plain(PlainCondition(attribute: "userId", operator: .equals, value: .string("123"))),
            .plain(PlainCondition(attribute: "device", operator: .equals, value: .string("mobile")))
        ])))
        XCTAssertNil(force1_1.segments)
        XCTAssertEqual(force1_1.variables, ["bar": .string("yoooooo")])
        XCTAssertEqual(force1_1.variation, "treatment")

        let feature2 = result.features[1]
        XCTAssertEqual(feature2.key, "f_foo")
        XCTAssertNil(feature2.deprecated)
        XCTAssertEqual(feature2.bucketBy, .single("userId"))
        XCTAssertEqual(feature2.ranges.count, 0)
        XCTAssertEqual(feature2.variations.count, 0)
        XCTAssertEqual(feature2.traffic.count, 2)
        
        let traffic2_1 = feature2.traffic[0]
        XCTAssertEqual(traffic2_1.key, "1")
        XCTAssertNil(traffic2_1.enabled)
        XCTAssertEqual(traffic2_1.percentage, 50000)
        XCTAssertEqual(traffic2_1.variation, nil)
        XCTAssertEqual(traffic2_1.segments, .multiple([.plain("myAccount")]))
        XCTAssertNil(traffic2_1.variables)
        XCTAssertEqual(traffic2_1.allocation.count, 0)
        
        let traffic2_2 = feature2.traffic[1]
        XCTAssertEqual(traffic2_2.key, "2")
        XCTAssertNil(traffic2_2.enabled)
        XCTAssertEqual(traffic2_2.percentage, 0)
        XCTAssertEqual(traffic2_2.variation, nil)
        XCTAssertEqual(traffic2_2.segments, .plain("*"))
        XCTAssertNil(traffic2_2.variables)
        XCTAssertEqual(traffic2_2.allocation.count, 0)
        
        let attribute1 = result.attributes[0]
        XCTAssertEqual(attribute1.key, "chapter")
        XCTAssertNil(attribute1.archived)
        XCTAssertNil(attribute1.capture)
        XCTAssertEqual(attribute1.type, "string")
        
        let attribute2 = result.attributes[1]
        XCTAssertEqual(attribute2.key, "deviceId")
        XCTAssertNil(attribute2.archived)
        XCTAssertTrue(attribute2.capture!)
        XCTAssertEqual(attribute2.type, "string")

        let attribute3 = result.attributes[2]
        XCTAssertEqual(attribute3.key, "userId")
        XCTAssertNil(attribute3.archived)
        XCTAssertTrue(attribute3.capture!)
        XCTAssertEqual(attribute3.type, "string")
    }
}
