import FeaturevisorSDK
import FeaturevisorTypes
import Files
import Foundation
import Yams

@main
struct FeaturevisorTestRunner {

    public static func main() throws {
        try FeaturevisorTestRunner().run()
    }

    func run() throws {

        let featuresTestDirectoryPath = CommandLine.arguments[1]  // TODO Handle command line parameters better

        let testSuits = try loadAllFeatureTestSuits(
            featuresTestDirectoryPath: featuresTestDirectoryPath
        )

        let sdkProduction = try SDKProvider.provide(
            for: .production,
            using: featuresTestDirectoryPath
        )
        let sdkStaging = try SDKProvider.provide(
            for: .staging,
            using: featuresTestDirectoryPath
        )

        let features = try loadAllFeatures(featuresTestDirectoryPath: featuresTestDirectoryPath)

        var totalTestSpecs = 0
        var failedTestSpecs = 0

        var totalAssertionsCount = 0
        var failedAssertionsCount = 0

        testSuits.forEach({ testSuit in

            // skip features which are not supported by iOS
            guard isFeatureSupported(by: "ios", featureKey: testSuit.feature, in: features) else {
                return
            }

            totalTestSpecs += 1
            totalAssertionsCount += testSuit.assertions.count

            print("\nTesting: \(testSuit.feature).feature.yml")
            print(" \(testSuit.feature).feature.yml")

            var isTestSpecFailing = false

            for (index, testCase) in testSuit.assertions.enumerated() {

                let isFeatureEnabledResult: Bool

                var expectedValuesFalses:
                    [VariableKey: (expected: VariableValue, got: VariableValue?)] = [:]

                switch testCase.environment {
                    case .staging:

                        guard
                            isFeatureExposed(
                                by: "ios",
                                environment: Environment.staging.rawValue,
                                featureKey: testSuit.feature,
                                in: features
                            )
                        else {
                            break
                        }

                        isFeatureEnabledResult =
                            sdkStaging.isEnabled(
                                featureKey: testSuit.feature,
                                context: testCase.context ?? [:]
                            ) == testCase.expectedToBeEnabled

                        testCase.expectedVariables?
                            .forEach({ (variableKey, variableExpectedValue) in
                                let variable = sdkStaging.getVariable(
                                    featureKey: testSuit.feature,
                                    variableKey: variableKey,
                                    context: testCase.context ?? [:]
                                )

                                if variable != variableExpectedValue {
                                    expectedValuesFalses[variableKey] = (
                                        variableExpectedValue, variable
                                    )
                                }
                            })

                        let finalAssertionResult =
                            isFeatureEnabledResult && expectedValuesFalses.isEmpty

                        let resultMark = finalAssertionResult ? "✔" : "✘"

                        isTestSpecFailing = isTestSpecFailing || !finalAssertionResult
                        failedAssertionsCount =
                            finalAssertionResult ? failedAssertionsCount : failedAssertionsCount + 1

                        //                    guard !result else { // Skip passing assertion
                        //                        break
                        //                    }

                        print(
                            " \(resultMark) Assertion #\(index): (staging) \(testCase.description)"
                        )
                        expectedValuesFalses.forEach({ (key, value) in
                            print("   => variable key: \(key)")
                            print("          => expected: \(value.expected)")
                            if let got = value.got {
                                print("          => variable key: \(got)")
                            }
                            else {
                                print("          => received: nil")
                            }
                        })

                    case .production:

                        guard
                            isFeatureExposed(
                                by: "ios",
                                environment: Environment.production.rawValue,
                                featureKey: testSuit.feature,
                                in: features
                            )
                        else {
                            break
                        }

                        isFeatureEnabledResult =
                            sdkProduction.isEnabled(
                                featureKey: testSuit.feature,
                                context: testCase.context ?? [:]
                            ) == testCase.expectedToBeEnabled

                        testCase.expectedVariables?
                            .forEach({ (variableKey, variableExpectedValue) in
                                let variable = sdkProduction.getVariable(
                                    featureKey: testSuit.feature,
                                    variableKey: variableKey,
                                    context: testCase.context ?? [:]
                                )

                                if variable != variableExpectedValue {
                                    expectedValuesFalses[variableKey] = (
                                        variableExpectedValue, variable
                                    )
                                }
                            })

                        let finalAssertionResult =
                            isFeatureEnabledResult && expectedValuesFalses.isEmpty

                        let resultMark = finalAssertionResult ? "✔" : "✘"

                        isTestSpecFailing = isTestSpecFailing || !finalAssertionResult
                        failedAssertionsCount =
                            finalAssertionResult ? failedAssertionsCount : failedAssertionsCount + 1

                        //                    guard !result else { // Skip passing assertion
                        //                        break
                        //                    }

                        print(
                            " \(resultMark) Assertion #\(index): (production) \(testCase.description)"
                        )
                        expectedValuesFalses.forEach({ (key, value) in
                            print("   => variable key: \(key)")
                            print("          => expected: \(value.expected)")
                            if let got = value.got {
                                print("          => variable key: \(got)")
                            }
                            else {
                                print("          => received: nil")
                            }
                        })
                }
            }

            failedTestSpecs = isTestSpecFailing ? failedTestSpecs + 1 : failedTestSpecs
        })

        print("\nTest specs: \(totalTestSpecs - failedTestSpecs) passed, \(failedTestSpecs) failed")
        print(
            "Assertions: \(totalAssertionsCount - failedAssertionsCount) passed, \(failedAssertionsCount) failed"
        )
    }
}

extension FeaturevisorTestRunner {

    func loadAllFeatures(featuresTestDirectoryPath: String) throws -> [Feature] {

        var features: [Feature] = []

        for file in try Folder(path: "\(featuresTestDirectoryPath)/features").files {

            let string = try String(contentsOfFile: file.path, encoding: .utf8)
            let decoder = YAMLDecoder()
            var feature = try decoder.decode(Feature.self, from: string.data(using: .utf8)!)
            feature.key = file.name  // TODO: remove yml

            features.append(feature)
        }

        return features
    }

    func loadAllFeatureTestSuits(featuresTestDirectoryPath: String) throws -> [FeatureTestSuitFile]
    {

        var featureTestSuits = [FeatureTestSuitFile]()

        for file in try Folder(path: "\(featuresTestDirectoryPath)/tests").files
            .filter({ $0.name.contains("feature") })
        {

            let string = try String(contentsOfFile: file.path, encoding: .utf8)
            let decoder = YAMLDecoder()
            let testSuitFile = try decoder.decode(
                FeatureTestSuitFile.self,
                from: string.data(using: .utf8)!
            )

            featureTestSuits.append(testSuitFile)
        }

        return featureTestSuits
    }

    func isFeatureSupported(
        by tag: String,
        featureKey: String,
        in features: [Feature]
    ) -> Bool {

        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {  // TODO: We need to cut off the extension
            return false
        }

        return feature.tags.contains(tag)
    }

    func isFeatureExposed(
        by tag: String,
        environment: String,
        featureKey: String,
        in features: [Feature]
    ) -> Bool {

        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {  // TODO: We need to cut off the extension
            return false
        }

        return feature.environments[environment]?.isExposed(for: tag) ?? false  // TODO: Handle it
    }
}
