import XCTest

@testable import FeaturevisorSDK
@testable import FeaturevisorTypes

extension ConditionsTests {

    func testSemverEquality() {

        //Given
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.3")

        //Then
        XCTAssertEqual(semver1, semver2)
    }

    func testSemverInequality() {

        //Given
        let semver1 = Semver("1.2.3")
        let semver2 = Semver("1.2.4")

        //Then
        XCTAssertNotEqual(semver1, semver2)
    }

    func testSemverGreaterThan() {

        //Given
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("1.9.9")

        //Then
        XCTAssertTrue(semver1 > semver2)
    }

    func testSemverGreaterThanOrEqual() {

        //Given
        let semver1 = Semver("2.0.0")
        let semver2 = Semver("2.0.0")

        //Then
        XCTAssertTrue(semver1 >= semver2)
    }

    func testSemverLessThan() {

        //Given
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.1")

        //Then
        XCTAssertTrue(semver1 < semver2)
    }

    func testSemverLessThanOrEqual() {

        //Given
        let semver1 = Semver("1.0.0")
        let semver2 = Semver("1.0.0")

        //Then
        XCTAssertTrue(semver1 <= semver2)
    }

    func testSemverParsing() {

        //Given
        let semver = Semver("3.2.1")

        //Then
        XCTAssertEqual(semver.major, 3)
        XCTAssertEqual(semver.minor, 2)
        XCTAssertEqual(semver.patch, 1)
    }

    func testSemverParsingInvalidVersion() {

        //Given
        let semver = Semver("invalid")

        //Then
        XCTAssertEqual(semver.major, 0)
        XCTAssertEqual(semver.minor, 0)
        XCTAssertEqual(semver.patch, 0)
    }
}
