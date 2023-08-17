import FeaturevisorSDKTests
import FeaturevisorTypesTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += FeaturevisorSDKTests.allTests()
tests += FeaturevisorTypesTests.allTests()
XCTMain(tests)
