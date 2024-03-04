import FeaturevisorSDK
import FeaturevisorTypes
import Files
import Foundation
import Commands
import Yams

@main
struct FeaturevisorTestRunner {

    public static func main() throws {
        try FeaturevisorTestRunner().run()
    }

    func run() throws {

        let featuresTestDirectoryPath = CommandLine.arguments[1]  // TODO Handle command line parameters better

        // Run Featurevisor CLI to build the datafiles
        Commands.Task.run("bash -c cd \(featuresTestDirectoryPath) && featurevisor build") // TODO: Handle better

        let testSuits = try loadAllFeatureTestSuits(
            featuresTestDirectoryPath: featuresTestDirectoryPath
        )

        let features = try loadAllFeatures(featuresTestDirectoryPath: featuresTestDirectoryPath)

        var totalTestSpecs = 0
        var failedTestSpecs = 0

        var totalAssertionsCount = 0
        var failedAssertionsCount = 0

        try testSuits.forEach({ testSuit in

            // skip features which are not supported by ios, tvos
            guard isFeatureSupported(by: [.ios, .tvos], featureKey: testSuit.feature, in: features) else {
                return
            }

            totalTestSpecs += 1
            totalAssertionsCount += testSuit.assertions.count

            print("\nTesting: \(testSuit.feature).feature.yml")
            print(" \(testSuit.feature).feature.yml")

            var isTestSpecFailing = false

            for (index, testCase) in testSuit.assertions.enumerated() {
                
                var sdks: [Feature.Tag: [Environment: FeaturevisorInstance]] = [:]
                
                try [Feature.Tag.ios, Feature.Tag.tvos].forEach({ tag in
                    let sdkProduction = try SDKProvider.provide(
                        for: tag,
                        under: .production,
                        using: featuresTestDirectoryPath,
                        assertionAt: testCase.at
                    )
                    let sdkStaging = try SDKProvider.provide(
                        for: tag,
                        under: .staging,
                        using: featuresTestDirectoryPath,
                        assertionAt: testCase.at
                    )
                    
                    sdks[tag] = [
                        .staging: sdkStaging,
                        .production: sdkProduction
                    ]
                })

                let isFeatureEnabledResult: Bool

                var expectedValuesFalses:
                    [VariableKey: (expected: VariableValue, got: VariableValue?)] = [:]

                switch testCase.environment {
                    case .staging:

                        guard
                            isFeatureExposed(
                                for: [.ios, .tvos],
                                under: Environment.staging.rawValue,
                                featureKey: testSuit.feature,
                                in: features
                            )
                        else {
                            break
                        }
                    
                    let tag = firstTagToVerifyAgainst(
                        tags: [.ios, .tvos],
                        environment: .staging,
                        featureKey: testSuit.feature,
                        in: features)

                        isFeatureEnabledResult =
                    sdks[tag]![.staging]!.isEnabled(
                                featureKey: testSuit.feature,
                                context: testCase.context ?? [:]
                            ) == testCase.expectedToBeEnabled

                        testCase.expectedVariables?
                            .forEach({ (variableKey, variableExpectedValue) in
                                let variable = sdks[tag]![.staging]!.getVariable(
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
                                print("          => received: \(got)")
                            }
                            else {
                                print("          => received: nil")
                            }
                        })

                    case .production:

                        guard
                            isFeatureExposed(
                                for: [.ios, .tvos],
                                under: Environment.production.rawValue,
                                featureKey: testSuit.feature,
                                in: features
                            )
                        else {
                            break
                        }
                    
                    let tag = firstTagToVerifyAgainst(
                        tags: [.ios, .tvos],
                        environment: .production,
                        featureKey: testSuit.feature,
                        in: features)

                        isFeatureEnabledResult =
                            sdks[tag]![.production]!.isEnabled(
                                featureKey: testSuit.feature,
                                context: testCase.context ?? [:]
                            ) == testCase.expectedToBeEnabled

                        testCase.expectedVariables?
                            .forEach({ (variableKey, variableExpectedValue) in
                                let variable = sdks[tag]![.production]!.getVariable(
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
                                print("          => received: \(got)")
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
        by tags: [Feature.Tag],
        featureKey: String,
        in features: [Feature]
    ) -> Bool {

        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {  // TODO: We need to cut off the extension
            return false
        }

        return feature.tags.contains(where: tags.contains)
    }
    
    // If feature is exposed for iOS or tvOS then it doesn't matter which datafile e.g. ios or tvos we use
    func firstTagToVerifyAgainst(
        tags: [Feature.Tag],
        environment: Environment,
        featureKey: String,
        in features: [Feature]) -> Feature.Tag {
            
            return tags.first(where: { isFeatureSupported(by: [$0], featureKey: featureKey, in: features) && isFeatureExposed(for: [$0], under: environment.rawValue, featureKey: featureKey, in: features)})! // TODO: Deal with force unwrap, redesign the way how we iterate the test suit
    }

    func isFeatureExposed(
        for tags: [Feature.Tag],
        under environment: String,
        featureKey: String,
        in features: [Feature]
    ) -> Bool {

        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {  // TODO: We need to cut off the extension
            return false
        }
        
        let supportedTag = tags.first(where: { tag in
            feature.environments[environment]?.isExposed(for: tag) ?? false  // TODO: Handle it
        })
        
        return supportedTag != nil
    }
}
