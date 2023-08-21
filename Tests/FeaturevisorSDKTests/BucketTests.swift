import Foundation
import XCTest

@testable import FeaturevisorSDK

final class BucketTests: XCTestCase {

    func testResolveBucketNumber() {

        // GIVEN
        let expectedResults: [String: Int] = [
            "foo": 20602,
            "bar": 89144,
            "123.foo": 3151,
            "123.bar": 9710,
            "123.456.foo": 14432,
            "123.456.bar": 1982
        ]

        expectedResults.forEach { value, result in
            // WHEN
            let number = Bucket.resolveNumber(forKey: value)

            // THEN
            XCTAssertEqual(number, result)
        }
    }
 }
