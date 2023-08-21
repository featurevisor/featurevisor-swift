import XCTest

@testable import FeaturevisorSDK

class FeaturevisorInstanceTests: XCTestCase {

    func testInitializationSuccessDatafileContentFetching() {
        
        // GIVEN
        let expectation: XCTestExpectation = expectation(description: "Expectation")
        
        MockURLProtocol.requestHandler = { request in
            let jsonString = "{\"schemaVersion\":\"1\",\"revision\":\"0.0.666\",\"attributes\":[],\"segments\":[],\"features\":[]}"
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response,  jsonString.data(using: .utf8))
        }

        var featurevisorOptions = InstanceOptions.default
        featurevisorOptions.sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        featurevisorOptions.datafileUrl = "https://featurevisor-awesome-url.com/tags.json"
        featurevisorOptions.onReady = { _ in
            expectation.fulfill()
        }

        // WHEN
        let instance = FeaturevisorInstance.createInstance(options: featurevisorOptions)
        wait(for: [expectation], timeout: 0.1)

        // THEN
        XCTAssertEqual(instance!.getRevision(), "0.0.666")
    }
}
