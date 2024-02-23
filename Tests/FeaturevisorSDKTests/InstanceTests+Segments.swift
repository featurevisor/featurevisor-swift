import Foundation
import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

extension FeaturevisorInstanceTests {

    func testShouldMatchWithMultipleConditionsInsideNOT() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [
                .init(key: "userId", type: "string", capture: true),
                .init(key: "country", type: "string"),
                .init(key: "device_os", type: "string"),
            ],
            segments: [
                .init(
                    key: "CountryDE",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("de"))
                    )
                ),
                .init(
                    key: "CountryAT",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("at"))
                    )
                ),
                .init(
                    key: "CountryCH",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("ch"))
                    )
                ),
                .init(
                    key: "OsIOS",
                    conditions: .plain(
                        .init(
                            attribute: "device_os",
                            operator: .in,
                            value: .array(["iOS", "iPadOS"])
                        )
                    )
                ),
            ],

            features: [
                .init(
                    key: "feature_test_key",
                    bucketBy: .single("userId"),
                    variablesSchema: [],
                    traffic: [
                        .init(
                            key: "1",
                            segments: .multiple([
                                .and(
                                    .init(and: [
                                        .plain("OsIOS"),
                                        .not(
                                            .init(not: [
                                                .plain("CountryAT"),
                                                .plain("CountryDE"),
                                                .plain("CountryCH"),
                                            ])
                                        ),
                                    ])
                                )
                            ]),
                            percentage: 100000,
                            allocation: [],
                            variables: [:]
                        ),
                        .init(
                            key: "2",
                            segments: .plain("*"),
                            percentage: 0,
                            allocation: []
                        ),
                    ]
                )
            ]
        )

        let sdk = try! createInstance(options: options)

        // WHEN
        // THEN
        XCTAssertFalse(
            sdk.isEnabled(
                featureKey: "feature_test_key",
                context: [
                    "device_os": AttributeValue.string("iOS"),
                    "country": AttributeValue.string("de"),
                ]
            )
        )

        XCTAssertTrue(
            sdk.isEnabled(
                featureKey: "feature_test_key",
                context: [
                    "device_os": AttributeValue.string("iOS"),
                    "country": AttributeValue.string("pl"),
                ]
            )
        )
    }

}
