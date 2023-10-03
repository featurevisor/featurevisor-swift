import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

class FeaturevisorInstanceTests: XCTestCase {

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
        wait(for: [expectation], timeout: 0.1)

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
                    required: [.withVariation(.init(key: "requiredKey", variation: "control"))],  // different variation
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
                    required: [.withVariation(.init(key: "requiredKey", variation: "treatment"))],  // desired variation
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
        wait(for: [expectation], timeout: 0.1)

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
        var options = InstanceOptions.default
        options.datafileUrl = "https://dazn.featurevisor.datafilecontent.com"
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
        XCTAssertEqual(sdk.getRevision(), "6.6.6")
    }

    func testHandleDatafileFetchReturnErrorResponse() {

        // GIVEN
        var wasDatafileContentFetchErrorThrown = false
        var options = InstanceOptions.default
        options.datafileUrl = "https://dazn.featurevisor.datafilecontent.com"
        options.handleDatafileFetch = { _ in
            return .failure(FeaturevisorError.unparseableJSON(data: nil, errorMessage: "Error :("))
        }
        options.logger = createLogger { level, message, details in
            guard case .error = level else {
                return
            }

            if message.contains("Failed to fetch datafile") {
                wasDatafileContentFetchErrorThrown = true
            }
        }
        options.datafile = DatafileContent(
            schemaVersion: "1",
            revision: "0.0.1",
            attributes: [],
            segments: [],
            features: []
        )

        // WHEN
        _ = try! createInstance(options: options)

        // THEN
        XCTAssertTrue(wasDatafileContentFetchErrorThrown)
    }
}
