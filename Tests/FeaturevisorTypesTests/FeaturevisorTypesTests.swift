import Foundation
import XCTest

@testable import FeaturevisorTypes

final class FeaturevisorTypesTests: XCTestCase {

    func testDecodeReturnsValidDatafileContentObjectForValidDatafileContentJSONResponse() throws {

        // GIVEN
        let path = Bundle.module.url(
            forResource: "DatafileContentValidResponse",
            withExtension: "json"
        )!

        // WHEN
        let json = try Data(contentsOf: path)
        let result = try JSONDecoder().decode(DatafileContent.self, from: json)

        // THEN
        XCTAssertEqual(result.revision, "0.0.13")
        XCTAssertEqual(result.schemaVersion, "1")
        XCTAssertEqual(result.attributes.count, 4)
        XCTAssertEqual(result.features.count, 3)
        XCTAssertEqual(result.segments.count, 3)

        let segment = result.segments[0]
        XCTAssertEqual(segment.key, "myAccount")
        XCTAssertNil(segment.archived)
        XCTAssertEqual(
            segment.conditions,
            .multiple([
                .plain(
                    PlainCondition(
                        attribute: "chapter",
                        operator: .equals,
                        value: .string("account")
                    )
                )
            ])
        )

        let feature1 = result.features[0]
        XCTAssertEqual(feature1.key, "e_bar")
        XCTAssertNil(feature1.deprecated)
        XCTAssertEqual(feature1.bucketBy, .single("userId"))
        XCTAssertEqual(feature1.ranges.count, 0)
        XCTAssertEqual(feature1.variablesSchema.count, 2)
        XCTAssertEqual(feature1.variations.count, 3)
        XCTAssertEqual(feature1.traffic.count, 2)
        XCTAssertEqual(feature1.force.count, 1)

        let variation11 = feature1.variations[0]
        XCTAssertEqual(variation11.value, "control")
        XCTAssertNil(variation11.description)
        XCTAssertEqual(variation11.weight, 33.34)
        XCTAssertEqual(variation11.variables!.count, 1)

        let variable11 = variation11.variables![0]
        XCTAssertEqual(variable11.key, "hero")
        XCTAssertEqual(
            variable11.value,
            .object([
                "title": .string("Hero Title for B"),
                "subtitle": .string("Hero Subtitle for B"),
                "alignment": .string("center for B"),
            ])
        )
        XCTAssertEqual(variable11.overrides!.count, 1)

        let override11 = variable11.overrides![0]
        XCTAssertEqual(
            override11.value,
            .object([
                "title": .string("Hero Title for B in DE or CH"),
                "subtitle": .string("Hero Subtitle for B in DE of CH"),
                "alignment": .string("center for B in DE or CH"),
            ])
        )
        XCTAssertEqual(
            override11.segments,
            .or(
                OrGroupSegment(or: [.plain("germany"), .plain("switzerland")])
            )
        )

        let variation12 = feature1.variations[1]
        XCTAssertEqual(variation12.value, "treatment")
        XCTAssertNil(variation12.description)
        XCTAssertEqual(variation12.weight, 33.33)
        XCTAssertNil(variation12.variables)

        let variation13 = feature1.variations[2]
        XCTAssertEqual(variation13.value, "anotherTreatment")
        XCTAssertNil(variation13.description)
        XCTAssertEqual(variation13.weight, 33.33)
        XCTAssertNil(variation13.variables)

        let traffic11 = feature1.traffic[0]
        XCTAssertEqual(traffic11.key, "1")
        XCTAssertNil(traffic11.enabled)
        XCTAssertEqual(traffic11.percentage, 100000)
        XCTAssertEqual(traffic11.variation, nil)
        XCTAssertEqual(traffic11.segments, .multiple([.plain("myAccount")]))
        XCTAssertNil(traffic11.variables)
        XCTAssertEqual(traffic11.allocation.count, 3)

        let allocation11 = traffic11.allocation[0]
        XCTAssertEqual(allocation11.variation, "control")
        XCTAssertEqual(allocation11.range.start, 0)
        XCTAssertEqual(allocation11.range.end, 33340)

        let allocation12 = traffic11.allocation[1]
        XCTAssertEqual(allocation12.variation, "treatment")
        XCTAssertEqual(allocation12.range.start, 33340)
        XCTAssertEqual(allocation12.range.end, 66670)

        let allocation13 = traffic11.allocation[2]
        XCTAssertEqual(allocation13.variation, "anotherTreatment")
        XCTAssertEqual(allocation13.range.start, 66670)
        XCTAssertEqual(allocation13.range.end, 100000)

        let traffic12 = feature1.traffic[1]
        XCTAssertEqual(traffic12.key, "2")
        XCTAssertNil(traffic12.enabled)
        XCTAssertEqual(traffic12.percentage, 0)
        XCTAssertEqual(traffic12.variation, nil)
        XCTAssertEqual(traffic12.segments, .plain("*"))
        XCTAssertNil(traffic12.variables)
        XCTAssertEqual(traffic12.allocation.count, 0)

        let variablesSchema11 = feature1.variablesSchema[0]
        XCTAssertEqual(variablesSchema11.key, "color")
        XCTAssertEqual(variablesSchema11.type, .string)
        XCTAssertEqual(variablesSchema11.defaultValue, .string("red"))

        let variablesSchema12 = feature1.variablesSchema[1]
        XCTAssertEqual(variablesSchema12.key, "hero")
        XCTAssertEqual(variablesSchema12.type, .object)
        XCTAssertEqual(
            variablesSchema12.defaultValue,
            .object([
                "title": .string("Hero Title"),
                "subtitle": .string("Hero Subtitle"),
                "alignment": .string("center"),
            ])
        )

        let force11 = feature1.force[0]
        XCTAssertTrue(force11.enabled!)
        XCTAssertEqual(
            force11.conditions,
            .and(
                AndCondition(and: [
                    .plain(
                        PlainCondition(
                            attribute: "userId",
                            operator: .equals,
                            value: .string("123")
                        )
                    ),
                    .plain(
                        PlainCondition(
                            attribute: "device",
                            operator: .equals,
                            value: .string("mobile")
                        )
                    ),
                ])
            )
        )
        XCTAssertNil(force11.segments)
        XCTAssertEqual(force11.variables, ["bar": .string("yoooooo")])
        XCTAssertEqual(force11.variation, "treatment")

        let feature2 = result.features[1]
        XCTAssertEqual(feature2.key, "f_foo")
        XCTAssertNil(feature2.deprecated)
        XCTAssertEqual(feature2.bucketBy, .single("userId"))
        XCTAssertEqual(feature2.ranges.count, 0)
        XCTAssertEqual(feature2.variations.count, 0)
        XCTAssertEqual(feature2.traffic.count, 2)

        let traffic21 = feature2.traffic[0]
        XCTAssertEqual(traffic21.key, "1")
        XCTAssertNil(traffic21.enabled)
        XCTAssertEqual(traffic21.percentage, 50000)
        XCTAssertEqual(traffic21.variation, nil)
        XCTAssertEqual(traffic21.segments, .multiple([.plain("myAccount")]))
        XCTAssertNil(traffic21.variables)
        XCTAssertEqual(traffic21.allocation.count, 0)

        let traffic22 = feature2.traffic[1]
        XCTAssertEqual(traffic22.key, "2")
        XCTAssertNil(traffic22.enabled)
        XCTAssertEqual(traffic22.percentage, 0)
        XCTAssertEqual(traffic22.variation, nil)
        XCTAssertEqual(traffic22.segments, .plain("*"))
        XCTAssertNil(traffic22.variables)
        XCTAssertEqual(traffic22.allocation.count, 0)

        let feature3 = result.features[2]
        XCTAssertEqual(feature3.key, "f_safe_mode_gcp")
        XCTAssertNil(feature3.deprecated)
        XCTAssertEqual(feature3.bucketBy, .single("userId"))
        XCTAssertEqual(feature3.ranges.count, 0)
        XCTAssertEqual(feature3.variations.count, 0)
        XCTAssertEqual(feature3.traffic.count, 2)

        let traffic31 = feature3.traffic[0]
        XCTAssertEqual(traffic31.key, "0")
        XCTAssertNil(traffic31.enabled)
        XCTAssertEqual(traffic31.percentage, 100000)
        XCTAssertEqual(traffic31.variation, nil)
        XCTAssertEqual(
            traffic31.segments,
            .multiple([.or(.init(or: [.plain("OsIOS"), .plain("OsAndroid"), .plain("OsTvOS")]))])
        )
        XCTAssertEqual(traffic31.variables?.count, 1)
        XCTAssertEqual(traffic31.allocation.count, 0)

        let traffic32 = feature3.traffic[1]
        XCTAssertEqual(traffic32.key, "1")
        XCTAssertNil(traffic32.enabled)
        XCTAssertEqual(traffic32.percentage, 100000)
        XCTAssertEqual(traffic32.variation, nil)
        XCTAssertEqual(traffic32.segments, .plain("PlatformWeb"))
        XCTAssertEqual(traffic32.variables?.count, 1)
        XCTAssertEqual(traffic32.allocation.count, 0)

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
