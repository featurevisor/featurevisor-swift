import XCTest

@testable import FeaturevisorSDK

class ConditionsTests: XCTestCase {

    func testSemverEquality() {
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.3")

        XCTAssertEqual(semver1, semver2)
    }

    func testSemverInequality() {
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.4")

        XCTAssertNotEqual(semver1, semver2)
    }

    func testSemverGreaterThan() {
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("1.9.9")

        XCTAssertTrue(semver1 > semver2)
    }

    func testSemverGreaterThanOrEqual() {
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("2.0.0")

        XCTAssertTrue(semver1 >= semver2)
    }

    func testSemverLessThan() {
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.1")

        XCTAssertTrue(semver1 < semver2)
    }

    func testSemverLessThanOrEqual() {
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.0")

        XCTAssertTrue(semver1 <= semver2)
    }

    func testSemverParsing() {
        let semver = Semver("3.2.1")

        XCTAssertEqual(semver.major, 3)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 1)
    }

    func testSemverParsingInvalidVersion() {
        let semver = Semver("invalid")

        XCTAssertEqual(semver.major, 0)
        XCTAssertEqual(semver.minor, 0)
        XCTAssertEqual(semver.patch, 0)
    }
}
