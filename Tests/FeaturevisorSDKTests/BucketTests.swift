import Foundation
import XCTest

@testable import FeaturevisorSDK

final class BucketTests: XCTestCase {
    
    func testResolveNumberForNotEmptyBucketKeyReturnsValidNumber() {
        // GIVEN
        
        // WHEN
        let number = Bucket.resolveNumber(forKey: "awesome-featurevisor-bucket-key")
        
        // THEN
        XCTAssertEqual(number, 12232)
    }
    
    func testResolveNumberForEmptyBucketKeyReturnsValidNumber() {
        // GIVEN
        
        // WHEN
        let number = Bucket.resolveNumber(forKey: "")
        
        // THEN
        XCTAssertEqual(number, 31759)
    }
 }
