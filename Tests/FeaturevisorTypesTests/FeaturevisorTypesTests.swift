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
        XCTAssertEqual(segment.conditions, .multiple([.plain(PlainCondition(attribute: "chapter", operator: .equals, value: .string("account")))]))
        
        let feature1 = result.features[0]
        XCTAssertEqual(feature1.key, "e_bar")
        XCTAssertNil(feature1.deprecated)
        XCTAssertEqual(feature1.bucketBy, .single("userId"))
        XCTAssertEqual(feature1.ranges.count, 0)
        XCTAssertEqual(feature1.variations.count, 3)
        XCTAssertEqual(feature1.traffic.count, 2)
        
        let variation1_1 = feature1.variations[0]
        XCTAssertEqual(variation1_1.value, "control")
        XCTAssertNil(variation1_1.description)
        XCTAssertEqual(variation1_1.weight, 33.34)
        XCTAssertNil(variation1_1.variables)
        
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
        XCTAssertEqual(traffic1_1.segments, .plain("[\"myAccount\"]"))
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
        XCTAssertEqual(traffic2_1.segments, .plain("[\"myAccount\"]"))
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
        
        let attribiute1 = result.attributes[0]
        XCTAssertEqual(attribiute1.key, "chapter")
        XCTAssertNil(attribiute1.archived)
        XCTAssertNil(attribiute1.capture)
        XCTAssertEqual(attribiute1.type, "string")
        
        let attribiute2 = result.attributes[1]
        XCTAssertEqual(attribiute2.key, "deviceId")
        XCTAssertNil(attribiute2.archived)
        XCTAssertTrue(attribiute2.capture!)
        XCTAssertEqual(attribiute2.type, "string")
        
        let attribiute3 = result.attributes[2]
        XCTAssertEqual(attribiute3.key, "userId")
        XCTAssertNil(attribiute3.archived)
        XCTAssertTrue(attribiute3.capture!)
        XCTAssertEqual(attribiute3.type, "string")
    }
}
