import Foundation
import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

extension FeaturevisorInstanceTests {

    func testGetVariableObjectReturnsValidObject() {

        // GIVEN
        class CustomObject: Decodable {
            let title: String
            let subtitle: String
            let score: Int
        }

        let variable = Variable(
            key: "hero",
            value: .object([
                "title": .string("Hero Title for B"),
                "subtitle": .string("Hero Subtitle for B"),
                "score": .integer(10),
            ]),
            overrides: nil
        )

        let variation = Variation(
            description: nil,
            value: "control",
            weight: 33.34,
            variables: [variable]
        )

        let allocation = Allocation(
            variation: "control",
            range: Range(start: 0, end: 33340)
        )

        let traffic = Traffic(
            key: "1",
            segments: .plain("*"),
            percentage: 100000,
            allocation: [allocation]
        )

        let variableSchema = VariableSchema(
            key: "hero",
            type: .object,
            defaultValue: .object([
                "title": .string("Hero Title for B"),
                "subtitle": .string("Hero Subtitle for B"),
                "score": .integer(10),
            ])
        )

        let feature = Feature(
            key: "e_bar",
            bucketBy: .single("userId"),
            variablesSchema: [variableSchema],
            variations: [variation],
            traffic: [traffic]
        )

        let segment = Segment(
            key: "*",
            conditions: .plain(
                PlainCondition(attribute: "chapter", operator: .equals, value: .string("account"))
            ),
            archived: nil
        )

        let datafileContent = DatafileContent(
            schemaVersion: "1.0",
            revision: "0.0.1",
            attributes: [],
            segments: [segment],
            features: [feature]
        )

        var options = InstanceOptions.default
        options.datafile = datafileContent

        let sdk = try! createInstance(options: options)

        // WHEN
        let object: CustomObject = sdk.getVariableObject(
            featureKey: "e_bar",
            variableKey: "hero",
            context: [:]
        )!

        // THEN
        XCTAssertEqual(object.title, "Hero Title for B")
        XCTAssertEqual(object.subtitle, "Hero Subtitle for B")
        XCTAssertEqual(object.score, 10)
    }
}
