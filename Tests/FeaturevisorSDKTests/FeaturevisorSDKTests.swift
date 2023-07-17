import Foundation
import XCTest

@testable import FeaturevisorSDK

final class FeaturevisorSDKTests: XCTestCase {
  func testExample() throws {
    // valid
    XCTAssertTrue(true, "valid: true")

    // invalid
    XCTAssertTrue(!false, "invalid: false")
  }
}
