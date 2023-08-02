import XCTest

@testable import FeaturevisorSDK  // Replace with your actual module name

class FeaturevisorInstanceTests: XCTestCase {

  func testInitializationWithoutDatafileOptions() {

    let featurevisorOptions = FeaturevisorSDK.InstanceOptions()

    XCTAssertThrowsError(try createInstance(options: featurevisorOptions)) { error in
      XCTAssertEqual(error as? FeaturevisorError, FeaturevisorError.missingDatafileOptions)
    }
  }
}
