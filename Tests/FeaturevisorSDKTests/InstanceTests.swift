import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

class FeaturevisorInstanceTests: XCTestCase {

    func testEncodingEvaluationWithNilValuesReturnsValidDatafileContent() throws {

        //GIVEN
        let evaluation = Evaluation(
            featureKey: "feature123",
            reason: .allocated
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(evaluation)

        //WHEN
        guard
            let decodedDictionary = try JSONSerialization.jsonObject(with: jsonData, options: [])
                as? [String: Any]
        else {
            XCTFail("Failed to decode JSON to a dictionary.")
            return
        }
        //THEN
        let expectedDictionary: [String: Any] = [
            "featureKey": "feature123",
            "reason": "allocated",
        ]

        XCTAssertEqual(decodedDictionary as NSDictionary, expectedDictionary as NSDictionary)
    }

    func testEncodeEvaluationReturnsValidDatafileContent() throws {

        //GIVEN
        let traffic = Traffic(
            key: "key",
            segments: .plain("segment"),
            percentage: 13,
            allocation: []
        )
        let overrideFeature = OverrideFeature(
            enabled: false,
            variation: "variation",
            variables: [:]
        )
        let variation = Variation(
            description: "description",
            value: "value",
            weight: 3,
            variables: []
        )
        let variableSchema = VariableSchema(
            key: "key",
            type: .object,
            defaultValue: .object(["": .boolean(false)])
        )

        let evaluation = Evaluation(
            featureKey: "feature123",
            reason: .allocated,
            bucketValue: 42,
            ruleKey: "rule456",
            enabled: true,
            traffic: traffic,
            sticky: overrideFeature,
            initial: overrideFeature,
            variation: variation,
            variationValue: "value",
            variableKey: "color",
            variableValue: .string(""),
            variableSchema: variableSchema
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(evaluation)

        //WHEN
        guard
            let decodedDictionary = try JSONSerialization.jsonObject(with: jsonData, options: [])
                as? [String: Any]
        else {
            XCTFail("Failed to decode JSON to a dictionary.")
            return
        }

        //THEN
        let expectedTraffic: [String: Any] = [
            "allocation": [Any](),
            "key": "key",
            "percentage": 13,
            "segments": [
                "plain": [
                    "_0": "segment"
                ]
            ],
        ]

        let expectedOverrideFeature: [String: Any] = [
            "enabled": false,
            "variables": [String: Any](),
            "variation": "variation",
        ]

        let expectedVariation: [String: Any] = [
            "description": "description",
            "value": "value",
            "variables": [Any](),
            "weight": 3,
        ]

        let expectedVariableSchema: [String: Any] = [
            "key": "key",
            "defaultValue": ["": 0],
            "type": "object",
        ]

        let expectedDictionary: [String: Any] = [
            "featureKey": "feature123",
            "reason": "allocated",
            "bucketValue": 42,
            "ruleKey": "rule456",
            "enabled": true,
            "traffic": expectedTraffic,
            "sticky": expectedOverrideFeature,
            "initial": expectedOverrideFeature,
            "variation": expectedVariation,
            "variationValue": "value",
            "variableKey": "color",
            "variableValue": "",
            "variableSchema": expectedVariableSchema,
        ]

        XCTAssertEqual(decodedDictionary as NSDictionary, expectedDictionary as NSDictionary)
    }

    func testCreateInstanceThrowsInvalidURLError() {

        // GIVEN
        var options = InstanceOptions.default
        options.datafileUrl = "hf://wrong url.com"

        // WHEN
        XCTAssertThrowsError(try createInstance(options: options)) { error in

            // THEN
            XCTAssertEqual(
                error as! FeaturevisorError,
                FeaturevisorError.invalidURL(string: "hf://wrong url.com")
            )
        }
    }

    func testCreateInstanceThrowsMissingDatafileOptionsError() {

        // GIVEN
        let options = InstanceOptions.default

        // WHEN
        XCTAssertThrowsError(try createInstance(options: options)) { error in

            // THEN
            XCTAssertEqual(error as! FeaturevisorError, FeaturevisorError.missingDatafileOptions)
        }
    }

    func testInitializationSuccessDatafileContentFetching() {

        // GIVEN
        let expectation: XCTestExpectation = expectation(description: "Expectation")

        MockURLProtocol.requestHandler = { request in
            let jsonString =
                "{\"schemaVersion\":\"1\",\"revision\":\"0.0.666\",\"attributes\":[],\"segments\":[],\"features\":[]}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonString.data(using: .utf8))
        }

        var featurevisorOptions = InstanceOptions.default
        featurevisorOptions.sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        featurevisorOptions.datafileUrl = "https://featurevisor-awesome-url.com/tags.json"
        featurevisorOptions.onReady = { _ in
            expectation.fulfill()
        }

        // WHEN
        let sdk = try! createInstance(options: featurevisorOptions)
        wait(for: [expectation], timeout: 0.5)

        // THEN
        XCTAssertEqual(sdk.getRevision(), "0.0.666")
    }

    func testShouldConfigurePlainBucketBy() {

        // GIVEN
        let featureKey = "test"
        let context: Context = ["userId": .string("123")]
        var capturedBucketKey = ""

        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                )
            ]
        )

        options.configureBucketKey =
            ({ feature, context, bucketKey in
                capturedBucketKey = bucketKey
                return bucketKey
            })

        let sdk = try! createInstance(options: options)

        // WHEN
        let isEnabled = sdk.isEnabled(featureKey: featureKey, context: context)
        let variation = sdk.getVariation(featureKey: featureKey, context: context)!

        // THEN
        XCTAssertTrue(isEnabled)
        XCTAssertEqual(variation, "control")
        XCTAssertEqual(capturedBucketKey, "123.test")
    }

    func testShouldConfigureAndBucketBy() {

        // GIVEN
        let featureKey = "test"
        let context: Context = ["userId": .string("123"), "organizationId": .string("456")]
        var capturedBucketKey = ""

        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .and(["userId", "organizationId"]),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                )
            ]
        )

        options.configureBucketKey =
            ({ feature, context, bucketKey in
                capturedBucketKey = bucketKey
                return bucketKey
            })

        let sdk = try! createInstance(options: options)

        // WHEN
        let variation = sdk.getVariation(featureKey: featureKey, context: context)!

        // THEN
        XCTAssertEqual(variation, "control")
        XCTAssertEqual(capturedBucketKey, "123.456.test")
    }

    func testShouldConfigureOrBucketBy() {

        // GIVEN
        var capturedBucketKey = ""

        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .or(.init(or: ["userId", "deviceId"])),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                )
            ]
        )

        options.configureBucketKey =
            ({ feature, context, bucketKey in
                capturedBucketKey = bucketKey
                return bucketKey
            })

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        XCTAssertTrue(
            sdk.isEnabled(
                featureKey: "test",
                context: ["userId": .string("123"), "deviceId": .string("456")]
            )
        )

        XCTAssertEqual(
            sdk.getVariation(
                featureKey: "test",
                context: ["userId": .string("123"), "deviceId": .string("456")]
            ),
            "control"
        )

        XCTAssertEqual(capturedBucketKey, "123.test")

        XCTAssertEqual(
            sdk.getVariation(
                featureKey: "test",
                context: ["deviceId": .string("456")]
            ),
            "control"
        )

        XCTAssertEqual(capturedBucketKey, "456.test")
    }

    func testShouldInterceptContext() {

        // GIVEN
        var intercepted = false

        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                )
            ]
        )
        options.interceptContext =
            ({ context in
                intercepted = true
                return context
            })

        // WHEN
        let sdk = try! createInstance(options: options)
        let variation = sdk.getVariation(
            featureKey: "test",
            context: [
                "userId": .string("123")
            ]
        )

        // THEN
        XCTAssertEqual(variation, "control")
        XCTAssertTrue(intercepted)
    }

    func testShouldActivateFeature() {

        // GIVEN
        var activated = false

        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                )
            ]
        )
        options.onActivation =
            ({ closure in
                activated = true
            })

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        let variation = sdk.getVariation(
            featureKey: "test",
            context: [
                "userId": .string("123")
            ]
        )

        XCTAssertFalse(activated)
        XCTAssertEqual(variation, "control")

        let activatedVariation = sdk.activate(
            featureKey: "test",
            context: [
                "userId": .string("123")
            ]
        )

        XCTAssertTrue(activated)
        XCTAssertEqual(activatedVariation, "control")
    }

    func testShouldHonourSimpleRequiredFeaturesDisabled() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "requiredKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 0,
                            allocation: []
                        )
                    ]
                ),
                Feature(
                    key: "myKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    required: [.featureKey("requiredKey")],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        )
                    ]
                ),
            ]
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        // should be disabled because required is disabled
        XCTAssertFalse(sdk.isEnabled(featureKey: "myKey"))
    }

    func testShouldHonourSimpleRequiredFeaturesEnabled() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "requiredKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,  // enabled
                            allocation: []
                        )
                    ]
                ),
                Feature(
                    key: "myKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    required: [.featureKey("requiredKey")],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        )
                    ]
                ),
            ]
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        // enabling required should enable the feature too
        XCTAssertTrue(sdk.isEnabled(featureKey: "myKey"))
    }

    // should be disabled because required has different variation
    func testShouldHonourRequiredFeaturesWithVariationDisabled() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "requiredKey",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                            ]
                        )
                    ]
                ),
                Feature(
                    key: "myKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    required: [
                        .withVariation(
                            .init(
                                key: "requiredKey",
                                variation: "control"
                            )
                        )
                    ],  // different variation
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        )
                    ]
                ),
            ]
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        XCTAssertFalse(sdk.isEnabled(featureKey: "myKey"))
    }

    // child should be enabled because required has desired variation
    func testShouldHonourRequiredFeaturesWithVariationEnabled() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "requiredKey",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                            ]
                        )
                    ]
                ),
                Feature(
                    key: "myKey",
                    bucketBy: .single("userId"),
                    variations: [],
                    required: [
                        .withVariation(
                            .init(
                                key: "requiredKey",
                                variation: "treatment"
                            )
                        )
                    ],  // desired variation
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        )
                    ]
                ),
            ]
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        XCTAssertTrue(sdk.isEnabled(featureKey: "myKey"))
    }

    func testShouldEmitWarningsForDeprecatedFeature() {

        // GIVEN
        let expectation: XCTestExpectation = expectation(description: "logger_log_exceptation")
        var deprecatedCount = 0
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [],
            segments: [],
            features: [
                Feature(
                    key: "test",
                    bucketBy: .single("userId"),
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                ),
                Feature(
                    key: "deprecatedTest",
                    bucketBy: .single("userId"),
                    deprecated: true,
                    variations: [
                        Variation(description: nil, value: "control", weight: nil, variables: nil),
                        Variation(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: nil
                        ),
                    ],
                    required: [],
                    traffic: [
                        Traffic(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                Allocation(
                                    variation: "control",
                                    range: FeaturevisorTypes.Range(start: 0, end: 100000)
                                ),
                                Allocation(
                                    variation: "treatment",
                                    range: FeaturevisorTypes.Range(start: 0, end: 0)
                                ),
                            ]
                        )
                    ]
                ),
            ]
        )

        options.logger = createLogger { level, message, details in
            guard case .warn = level else {
                return
            }

            if message.contains("is deprecated") {
                deprecatedCount += 1
                expectation.fulfill()
            }
        }

        // WHEN
        let sdk = try! createInstance(options: options)
        let testVariation = sdk.getVariation(
            featureKey: "test",
            context: ["userId": .string("123")]
        )
        let deprecatedTestVariation = sdk.getVariation(
            featureKey: "deprecatedTest",
            context: ["userId": .string("123")]
        )

        wait(for: [expectation], timeout: 1)

        // THEN
        XCTAssertEqual(testVariation, "control")
        XCTAssertEqual(deprecatedTestVariation, "control")
        XCTAssertEqual(deprecatedCount, 1)
    }

    func testShouldRefreshDatafile() {

        // GIVEN
        var revision = 1
        var refreshed = false
        var updatedViaOption = false

        let expectation: XCTestExpectation = expectation(description: "Expectation")

        MockURLProtocol.requestHandler = { request in
            let jsonString =
                "{\"schemaVersion\":\"1\",\"revision\":\"\(revision)\",\"attributes\":[],\"segments\":[],\"features\":[]}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            revision += 1
            return (response, jsonString.data(using: .utf8))
        }

        var options: InstanceOptions = .default
        options.sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        options.datafileUrl = "https://featurevisor-awesome-url.com/tags.json"
        options.onRefresh =
            ({ _ in
                refreshed = true
            })
        options.onUpdate =
            ({ _ in
                updatedViaOption = true
                expectation.fulfill()
            })

        // WHEN
        let sdk = try! createInstance(options: options)
        sdk.refresh()
        wait(for: [expectation], timeout: 0.5)

        // THEN
        XCTAssertEqual(sdk.getRevision(), "2")
        XCTAssertTrue(refreshed)
        XCTAssertTrue(updatedViaOption)
    }

    func testShouldStartRefreshing() {

        // GIVEN
        var revision = 1
        var refreshedCount = 0
        let refreshInterval = 1.0
        let expectedRefreshCount = 3

        MockURLProtocol.requestHandler = { request in
            let jsonString =
                "{\"schemaVersion\":\"1\",\"revision\":\"\(revision)\",\"attributes\":[],\"segments\":[],\"features\":[]}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            revision += 1
            return (response, jsonString.data(using: .utf8))
        }

        var options: InstanceOptions = .default
        options.sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        options.refreshInterval = refreshInterval
        options.datafileUrl = "https://featurevisor-awesome-url.com/tags.json"
        options.onRefresh =
            ({ _ in
                refreshedCount += 1
            })

        // WHEN
        let sdk = try! createInstance(options: options)

        while refreshedCount < expectedRefreshCount {
            Thread.sleep(forTimeInterval: 0.1)
        }

        // THEN
        XCTAssertEqual(sdk.getRevision(), "4")
        XCTAssertEqual(refreshedCount, expectedRefreshCount)
    }

    func testShouldStopRefreshing() {

        // GIVEN
        var isRefreshingStopped = false
        var revision = 1
        let refreshInterval = 1.0

        MockURLProtocol.requestHandler = { request in
            let jsonString =
                "{\"schemaVersion\":\"1\",\"revision\":\"\(revision)\",\"attributes\":[],\"segments\":[],\"features\":[]}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            revision += 1
            return (response, jsonString.data(using: .utf8))
        }

        var options: InstanceOptions = .default
        options.sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        options.refreshInterval = refreshInterval
        options.datafileUrl = "https://featurevisor-awesome-url.com/tags.json"
        options.logger = createLogger { level, message, details in
            guard case .warn = level else {
                return
            }

            if message.contains("refreshing has stopped") {
                isRefreshingStopped = true
            }
        }

        // WHEN
        let sdk = try! createInstance(options: options)

        XCTAssertEqual(isRefreshingStopped, false)

        sdk.stopRefreshing()

        // THEN
        XCTAssertEqual(isRefreshingStopped, true)
    }

    func testSetDatafileByValidJSON() {

        // GIVEN
        var options = InstanceOptions.default
        options.datafile = DatafileContent(
            schemaVersion: "",
            revision: "",
            attributes: [],
            segments: [],
            features: []
        )
        let sdk = try! createInstance(options: options)

        // WHEN
        sdk.setDatafile(
            "{\"schemaVersion\":\"1\",\"revision\":\"0.0.66\",\"attributes\":[],\"segments\":[],\"features\":[]}"
        )

        // THEN
        XCTAssertEqual(sdk.getRevision(), "0.0.66")
    }

    func testSetDatafileByDatafileContent() {

        // GIVEN
        let datafileContent = DatafileContent(
            schemaVersion: "1",
            revision: "0.0.66",
            attributes: [],
            segments: [],
            features: []
        )

        var options = InstanceOptions.default
        options.datafile = DatafileContent(
            schemaVersion: "",
            revision: "",
            attributes: [],
            segments: [],
            features: []
        )
        let sdk = try! createInstance(options: options)

        // WHEN
        sdk.setDatafile(datafileContent)

        // THEN
        XCTAssertEqual(sdk.getRevision(), "0.0.66")
    }

    func testSetDatafileByInvalidJSONReturnsError() {

        // GIVEN
        var errorCount = 0
        var options = InstanceOptions.default
        options.logger = createLogger { level, message, details in
            guard case .error = level else {
                return
            }

            if message.contains("could not parse datafile") {
                errorCount += 1
            }
        }
        options.datafile = DatafileContent(
            schemaVersion: "",
            revision: "",
            attributes: [],
            segments: [],
            features: []
        )

        let sdk = try! createInstance(options: options)

        // WHEN
        sdk.setDatafile(
            "{\"schemaVersion\":1,\"revision\":\"0.0.66\", attributes:[],\"segments\":[],\"features\":[]}"
        )

        // THEN
        XCTAssertEqual(errorCount, 1)
        XCTAssertEqual(sdk.getRevision(), "")
    }

    func testHandleDatafileFetchReturnsValidResponse() {

        // GIVEN
        let expectation = expectation(description: "datafile_success_response_expectation")
        var options = InstanceOptions.default
        options.datafileUrl = "https://featurevisor.datafilecontent.com"
        options.onReady = { _ in
            expectation.fulfill()
        }
        options.handleDatafileFetch = { _ in
            let datafileContent = DatafileContent(
                schemaVersion: "2",
                revision: "6.6.6",
                attributes: [],
                segments: [],
                features: []
            )

            return .success(datafileContent)
        }
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "0.0.1",
            attributes: [],
            segments: [],
            features: []
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        waitForExpectations(timeout: 1)
        XCTAssertEqual(sdk.getRevision(), "6.6.6")
    }

    func testHandleDatafileFetchReturnErrorResponse() {

        // GIVEN
        let expectation = expectation(description: "datafile_error_response_expectation")
        var wasDatafileContentFetchErrorThrown = false
        var errorThrownDetails: String?

        var options = InstanceOptions.default
        options.logger = createLogger { level, message, details in
            guard case .error = level else {
                return
            }

            if message.contains("failed to fetch datafile") {
                wasDatafileContentFetchErrorThrown = true
                errorThrownDetails = details?.description
            }

            expectation.fulfill()
        }
        options.datafileUrl = "https://featurevisor.datafilecontent.com"
        options.handleDatafileFetch = { _ in
            .failure(FeaturevisorError.unparseableJSON(data: nil, errorMessage: "Error :("))
        }
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "0.0.1",
            attributes: [],
            segments: [],
            features: []
        )

        // WHEN
        let sdk = try! createInstance(options: options)
        waitForExpectations(timeout: 1)

        // THEN
        XCTAssertFalse(sdk.isReady())
        XCTAssertTrue(wasDatafileContentFetchErrorThrown)
        XCTAssertEqual(
            errorThrownDetails,
            "[\"error\": FeaturevisorSDK.FeaturevisorError.unparseableJSON(data: nil, errorMessage: \"Error :(\")]"
        )
    }

    func testShouldGetVariable() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [
                .init(key: "userId", type: "string", capture: true),
                .init(key: "country", type: "string"),
            ],
            segments: [
                .init(
                    key: "netherlands",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("nl"))
                    )
                ),
                .init(
                    key: "belgium",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("be"))
                    )
                ),
            ],
            features: [
                .init(
                    key: "test",
                    bucketBy: .single("userId"),
                    variablesSchema: [
                        .init(key: "color", type: .string, defaultValue: .string("red")),
                        .init(key: "showSidebar", type: .boolean, defaultValue: .boolean(false)),
                        .init(
                            key: "sidebarTitle",
                            type: .string,
                            defaultValue: .string("sidebar title")
                        ),
                        .init(key: "count", type: .integer, defaultValue: .integer(0)),
                        .init(key: "price", type: .double, defaultValue: .double(9.99)),
                        .init(
                            key: "paymentMethods",
                            type: .array,
                            defaultValue: .array(["paypal", "creditcard"])
                        ),
                        .init(
                            key: "flatConfig",
                            type: .object,
                            defaultValue: .object(["key": .string("value")])
                        ),
                        .init(
                            key: "nestedConfig",
                            type: .json,
                            defaultValue: .json("{\"key\": {\"nested\": \"value\"}}")
                        ),
                    ],
                    variations: [
                        .init(description: nil, value: "control", weight: nil, variables: nil),
                        .init(
                            description: nil,
                            value: "treatment",
                            weight: nil,
                            variables: [
                                .init(
                                    key: "showSidebar",
                                    value: .boolean(true),
                                    overrides: [
                                        .init(
                                            value: .boolean(false),
                                            conditions: .multiple([
                                                .plain(
                                                    .init(
                                                        attribute: "country",
                                                        operator: .equals,
                                                        value: .string("de")
                                                    )
                                                )
                                            ])
                                        ),
                                        .init(
                                            value: .boolean(false),
                                            segments: .multiple([.plain("netherlands")])
                                        ),
                                    ]
                                ),
                                .init(
                                    key: "sidebarTitle",
                                    value: .string("sidebar title from variation"),
                                    overrides: [
                                        .init(
                                            value: .string("German title"),
                                            conditions: .multiple([
                                                .plain(
                                                    .init(
                                                        attribute: "country",
                                                        operator: .equals,
                                                        value: .string("de")
                                                    )
                                                )
                                            ])
                                        ),
                                        .init(
                                            value: .string("Dutch title"),
                                            segments: .multiple([.plain("netherlands")])
                                        ),
                                    ]
                                ),
                            ]
                        ),
                    ],
                    traffic: [
                        .init(
                            key: "2",
                            segments: .plain("belgium"),
                            percentage: 100000,
                            allocation: [
                                .init(variation: "control", range: .init(start: 0, end: 0)),
                                .init(variation: "treatment", range: .init(start: 0, end: 100000)),
                            ],
                            variation: "control",
                            variables: ["color": .string("black")]
                        ),
                        .init(
                            key: "1",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: [
                                .init(variation: "control", range: .init(start: 0, end: 0)),
                                .init(variation: "treatment", range: .init(start: 0, end: 100000)),
                            ]
                        ),
                    ],
                    force: [
                        .init(
                            variation: "control",
                            variables: ["color": .string("red and white")],
                            conditions: .multiple([
                                .plain(
                                    .init(
                                        attribute: "userId",
                                        operator: .equals,
                                        value: .string("user-ch")
                                    )
                                )
                            ]),
                            enabled: true
                        ),
                        .init(
                            conditions: .multiple([
                                .plain(
                                    .init(
                                        attribute: "userId",
                                        operator: .equals,
                                        value: .string("user-gb")
                                    )
                                )
                            ]),
                            enabled: false
                        ),
                        .init(
                            variation: "treatment",
                            conditions: .multiple([
                                .plain(
                                    .init(
                                        attribute: "userId",
                                        operator: .equals,
                                        value: .string("user-forced-variation")
                                    )
                                )
                            ]),
                            enabled: true
                        ),
                    ]
                )
            ]
        )

        // WHEN
        let sdk = try! createInstance(options: options)

        // THEN
        XCTAssertEqual(
            sdk.getVariation(featureKey: "test", context: ["userId": .string("123")]),
            "treatment"
        )
        XCTAssertEqual(
            sdk.getVariation(
                featureKey: "test",
                context: ["userId": .string("123"), "country": .string("be")]
            ),
            "control"
        )
        XCTAssertEqual(
            sdk.getVariation(featureKey: "test", context: ["userId": .string("user-ch")]),
            "control"
        )

        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "color",
                context: ["userId": .string("123")]
            )?
            .value as! String,
            "red"
        )
        XCTAssertEqual(
            sdk.getVariableString(
                featureKey: "test",
                variableKey: "color",
                context: ["userId": .string("123")]
            ),
            "red"
        )
        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "color",
                context: ["userId": .string("123"), "country": .string("be")]
            )?
            .value as! String,
            "black"
        )
        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "color",
                context: ["userId": .string("user-ch")]
            )?
            .value as! String,
            "red and white"
        )

        XCTAssertTrue(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "showSidebar",
                context: ["userId": .string("123")]
            )?
            .value as! Bool
        )
        XCTAssertTrue(
            sdk.getVariableBoolean(
                featureKey: "test",
                variableKey: "showSidebar",
                context: ["userId": .string("123")]
            )!
        )
        XCTAssertFalse(
            sdk.getVariableBoolean(
                featureKey: "test",
                variableKey: "showSidebar",
                context: ["userId": .string("123"), "country": .string("nl")]
            )!
        )
        XCTAssertFalse(
            sdk.getVariableBoolean(
                featureKey: "test",
                variableKey: "showSidebar",
                context: ["userId": .string("123"), "country": .string("de")]
            )!
        )

        XCTAssertEqual(
            sdk.getVariableString(
                featureKey: "test",
                variableKey: "sidebarTitle",
                context: ["userId": .string("user-forced-variation"), "country": .string("de")]
            )!,
            "German title"
        )
        XCTAssertEqual(
            sdk.getVariableString(
                featureKey: "test",
                variableKey: "sidebarTitle",
                context: ["userId": .string("user-forced-variation"), "country": .string("nl")]
            )!,
            "Dutch title"
        )
        XCTAssertEqual(
            sdk.getVariableString(
                featureKey: "test",
                variableKey: "sidebarTitle",
                context: ["userId": .string("user-forced-variation"), "country": .string("be")]
            )!,
            "sidebar title from variation"
        )

        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "count",
                context: ["userId": .string("123")]
            )?
            .value as! Int,
            0
        )
        XCTAssertEqual(
            sdk.getVariableInteger(
                featureKey: "test",
                variableKey: "count",
                context: ["userId": .string("123")]
            ),
            0
        )

        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "price",
                context: ["userId": .string("123")]
            )?
            .value as! Double,
            9.99
        )
        XCTAssertEqual(
            sdk.getVariableDouble(
                featureKey: "test",
                variableKey: "price",
                context: ["userId": .string("123")]
            ),
            9.99
        )

        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "paymentMethods",
                context: ["userId": .string("123")]
            )?
            .value as! [String],
            ["paypal", "creditcard"]
        )
        XCTAssertEqual(
            sdk.getVariableArray(
                featureKey: "test",
                variableKey: "paymentMethods",
                context: ["userId": .string("123")]
            ),
            ["paypal", "creditcard"]
        )

        XCTAssertEqual(
            (sdk.getVariable(
                featureKey: "test",
                variableKey: "flatConfig",
                context: ["userId": .string("123")]
            )?
            .value as! VariableObjectValue)["key"]?
            .value as! String,
            "value"
        )
        XCTAssertEqual(
            sdk.getVariableObject(
                featureKey: "test",
                variableKey: "flatConfig",
                context: ["userId": .string("123")]
            ),
            ["key": "value"]
        )

        XCTAssertEqual(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "nestedConfig",
                context: ["userId": .string("123")]
            )?
            .value as! String,
            "{\"key\": {\"nested\": \"value\"}}"
        )
        XCTAssertEqual(
            sdk.getVariableJSON(
                featureKey: "test",
                variableKey: "nestedConfig",
                context: ["userId": .string("123")]
            ),
            ["key": ["nested": "value"]]
        )

        // non existing
        XCTAssertNil(sdk.getVariable(featureKey: "test", variableKey: "nonExisting"))
        XCTAssertNil(sdk.getVariable(featureKey: "nonExistingFeature", variableKey: "nonExisting"))

        // disabled
        XCTAssertNil(
            sdk.getVariable(
                featureKey: "test",
                variableKey: "color",
                context: ["userId": .string("user-gb")]
            )
        )
    }

    func testShouldGetVariablesWithoutAnyVariations() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [
                .init(key: "userId", type: "string", capture: true),
                .init(key: "country", type: "string"),
            ],
            segments: [
                .init(
                    key: "netherlands",
                    conditions: .plain(
                        .init(attribute: "country", operator: .equals, value: .string("nl"))
                    )
                )
            ],
            features: [
                .init(
                    key: "test",
                    bucketBy: .single("userId"),
                    variablesSchema: [
                        .init(key: "color", type: .string, defaultValue: .string("red"))
                    ],
                    traffic: [
                        .init(
                            key: "1",
                            segments: .plain("netherlands"),
                            percentage: 100000,
                            allocation: [],
                            variables: ["color": .string("orange")]
                        ),
                        .init(
                            key: "2",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        ),
                    ]
                )
            ]
        )

        let sdk = try! createInstance(options: options)

        // WHEN
        let variableWithDefaultContext = sdk.getVariable(
            featureKey: "test",
            variableKey: "color",
            context: ["userId": .string("123")]
        )

        let variableWithExtendedContextByCountry = sdk.getVariable(
            featureKey: "test",
            variableKey: "color",
            context: ["userId": .string("123"), "country": .string("nl")]
        )

        // THEN
        XCTAssertEqual(variableWithDefaultContext!.value as! String, "red")
        XCTAssertEqual(variableWithExtendedContextByCountry!.value as! String, "orange")
    }

    func testShouldParseNilVariables() {

        // GIVEN
        var options: InstanceOptions = .default
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "1.0",
            attributes: [
                .init(key: "userId", type: "string", capture: true)
            ],
            segments: [
                .init(
                    key: "signedIn",
                    conditions: .plain(
                        .init(attribute: "userId", operator: .notEquals, value: .unknown)
                    )
                )
            ],
            features: [
                .init(
                    key: "test",
                    bucketBy: .single("userId"),
                    variablesSchema: [
                        .init(key: "color", type: .string, defaultValue: .string("red"))
                    ],
                    traffic: [
                        .init(
                            key: "1",
                            segments: .plain("signedIn"),
                            percentage: 100000,
                            allocation: [],
                            variables: ["color": .string("orange")]
                        ),
                        .init(
                            key: "2",
                            segments: .plain("*"),
                            percentage: 100000,
                            allocation: []
                        ),
                    ]
                )
            ]
        )

        let sdk = try! createInstance(options: options)

        // WHEN
        let variableWithSignedInUser = sdk.getVariable(
            featureKey: "test",
            variableKey: "color",
            context: ["userId": .string("123")]
        )

        let variableWithNotSignedInUser = sdk.getVariable(
            featureKey: "test",
            variableKey: "color",
            context: ["userId": .unknown]
        )

        // THEN
        XCTAssertEqual(variableWithSignedInUser!.value as! String, "orange")
        XCTAssertEqual(variableWithNotSignedInUser!.value as! String, "red")
    }
}
