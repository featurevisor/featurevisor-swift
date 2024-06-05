import ArgumentParser
import Commands
import FeaturevisorSDK
import FeaturevisorTypes
import Files
import Foundation
import Yams

@main
struct FeaturevisorCLI: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "Featurevisor CLI.",
        subcommands: [Benchmark.self, Evaluate.self, Test.self]
    )
}

extension FeaturevisorCLI {

    struct Benchmark: ParsableCommand {

        struct Options {
            let environment: Environment
            let feature: FeatureKey
            let n: Int
            let context: [AttributeKey: AttributeValue]
            let variation: Bool
            let variable: String?
        }

        struct Output {
            let value: Any?
            let duration: TimeInterval
        }

        static let configuration = CommandConfiguration(
            abstract:
                "You can measure how fast or slow your SDK evaluations are for particular features."
        )

        @Option(
            help:
                "The option is used to specify the environment which will be used for the benchmark run."
        )
        var environment: String

        @Option(
            help:
                "The option is used to specify the feature key which will be used for the benchmark run."
        )
        var feature: String

        @Option(
            help:
                "The option is used to specify the context which will be used for the benchmark run."
        )
        var context: String

        @Option(
            name: .customShort("n"),
            help: "The option is used to specify the number of iterations to run the benchmark for."
        )
        var numberOfIterations: Int

        @Option(
            help: "To benchmark evaluating a feature's variable via SDK's `.getVariable()` method."
        )
        var variable: String? = nil

        @Flag(
            help:
                "To benchmark evaluating a feature's variation via SDK's `.getVariation()` method."
        )
        var variation: Bool = false

        mutating func run() throws {

            let _context = try JSONDecoder()
                .decode(
                    [AttributeKey: AttributeValue].self,
                    from: context.data(using: .utf8)!
                )

            let options: Options = .init(
                environment: .init(rawValue: environment)!,
                feature: feature,
                n: numberOfIterations,
                context: _context,
                variation: variation,
                variable: variable
            )

            benchmarkFeature(options: options)
        }
    }
}

extension FeaturevisorCLI {

    struct Evaluate: ParsableCommand {

        struct Options {
            let environment: Environment
            let feature: FeatureKey
            let context: [AttributeKey: AttributeValue]
        }

        struct Output {
            let value: Any?
            let duration: TimeInterval
        }

        static let configuration = CommandConfiguration(
            abstract:
                "To learn why certain values (like feature and its variation or variables) are evaluated as they are."
        )

        @Option(
            help:
                "The option is used to specify the environment which will be used for the evaluation run."
        )
        var environment: String

        @Option(
            help:
                "The option is used to specify the feature key which will be used for the evaluation run."
        )
        var feature: String

        @Option(
            help:
                "The option is used to specify the context which will be used for the benchmark run."
        )
        var context: String

        mutating func run() throws {

            let _context = try JSONDecoder()
                .decode(
                    [AttributeKey: AttributeValue].self,
                    from: context.data(using: .utf8)!
                )

            let options: Options = .init(
                environment: .init(rawValue: environment)!,
                feature: feature,
                context: _context
            )

            evaluateFeature(options: options)
        }
    }
}

extension FeaturevisorCLI {

    struct Test: ParsableCommand {

        static let configuration = CommandConfiguration(
            abstract:
                "We can write test specs in the same expressive way as we defined our features to test against Featurevisor Swift SDK.",
            subcommands: [Benchmark.self]
        )

        @Argument(help: "The path to features test directory.")
        var featuresTestDirectoryPath: String

        @Flag(help: "If you are interested to see only the test specs that fail.")
        var onlyFailures = false

        mutating func run() throws {

            // Run Featurevisor CLI to build the datafiles
            // TODO: Handle better, react on errors etc.
            Commands.Task.run("bash -c cd \(featuresTestDirectoryPath) && featurevisor build")

            let testSuits = try loadAllFeatureTestSuits(
                featuresTestDirectoryPath: featuresTestDirectoryPath
            )

            let features = try loadAllFeatures(featuresTestDirectoryPath: featuresTestDirectoryPath)

            var totalElapsedDurationInMilliseconds: UInt64 = 0

            var totalTestSpecs = 0
            var failedTestSpecs = 0

            var totalAssertionsCount = 0
            var failedAssertionsCount = 0

            try testSuits.forEach({ testSuit in

                // skip features which are not supported by ios, tvos
                guard
                    isFeatureSupported(
                        by: [.ios, .tvos],
                        featureKey: testSuit.feature,
                        in: features
                    )
                else {
                    return
                }

                let output = FeatureResultOutputBuilder(
                    feature: testSuit.feature,
                    onlyFailures: onlyFailures
                )

                totalTestSpecs += 1
                totalAssertionsCount += testSuit.assertions.count

                var isTestSpecFailing = false

                for (index, testCase) in testSuit.assertions.enumerated() {

                    var sdks: [Feature.Tag: [Environment: FeaturevisorInstance]] = [:]

                    try [Feature.Tag.ios, Feature.Tag.tvos]
                        .forEach({ tag in
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
                                .production: sdkProduction,
                            ]
                        })

                    let isFeatureEnabledResult: Bool

                    var expectedValueFailures:
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
                                in: features
                            )

                            let startTime = DispatchTime.now()

                            isFeatureEnabledResult =
                                sdks[tag]![.staging]!
                                .isEnabled(
                                    featureKey: testSuit.feature,
                                    context: testCase.context ?? [:]
                                ) == testCase.expectedToBeEnabled

                            testCase.expectedVariables?
                                .forEach({ (variableKey, variableExpectedValue) in
                                    let variable = sdks[tag]![.staging]!
                                        .getVariable(
                                            featureKey: testSuit.feature,
                                            variableKey: variableKey,
                                            context: testCase.context ?? [:]
                                        )

                                    if variable != variableExpectedValue {
                                        expectedValueFailures[variableKey] = (
                                            variableExpectedValue, variable
                                        )
                                    }
                                })

                            let endTime = DispatchTime.now()

                            let finalAssertionResult =
                                isFeatureEnabledResult && expectedValueFailures.isEmpty

                            isTestSpecFailing = isTestSpecFailing || !finalAssertionResult
                            failedAssertionsCount =
                                finalAssertionResult
                                ? failedAssertionsCount : failedAssertionsCount + 1

                            let elapsedTime =
                                endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                            totalElapsedDurationInMilliseconds += elapsedTime

                            output.addAssertion(
                                environment: testCase.environment,
                                index: index,
                                assertionResult: finalAssertionResult,
                                expectedValueFailures: expectedValueFailures,
                                description: testCase.description,
                                elapsedTime: elapsedTime
                            )

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
                                in: features
                            )

                            let startTime = DispatchTime.now()

                            isFeatureEnabledResult =
                                sdks[tag]![.production]!
                                .isEnabled(
                                    featureKey: testSuit.feature,
                                    context: testCase.context ?? [:]
                                ) == testCase.expectedToBeEnabled

                            testCase.expectedVariables?
                                .forEach({ (variableKey, variableExpectedValue) in
                                    let variable = sdks[tag]![.production]!
                                        .getVariable(
                                            featureKey: testSuit.feature,
                                            variableKey: variableKey,
                                            context: testCase.context ?? [:]
                                        )

                                    if variable != variableExpectedValue {
                                        expectedValueFailures[variableKey] = (
                                            variableExpectedValue, variable
                                        )
                                    }
                                })

                            let endTime = DispatchTime.now()

                            let finalAssertionResult =
                                isFeatureEnabledResult && expectedValueFailures.isEmpty

                            isTestSpecFailing = isTestSpecFailing || !finalAssertionResult
                            failedAssertionsCount =
                                finalAssertionResult
                                ? failedAssertionsCount : failedAssertionsCount + 1

                            let elapsedTime =
                                endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                            totalElapsedDurationInMilliseconds += elapsedTime

                            output.addAssertion(
                                environment: testCase.environment,
                                index: index,
                                assertionResult: finalAssertionResult,
                                expectedValueFailures: expectedValueFailures,
                                description: testCase.description,
                                elapsedTime: elapsedTime
                            )
                    }
                }

                if let output = output.build() {
                    print(output)
                }

                failedTestSpecs = isTestSpecFailing ? failedTestSpecs + 1 : failedTestSpecs
            })

            print(
                "\nTest specs: \(totalTestSpecs - failedTestSpecs) passed, \(failedTestSpecs) failed"
            )
            print(
                "Assertions: \(totalAssertionsCount - failedAssertionsCount) passed, \(failedAssertionsCount) failed"
            )

            print(
                "Assertions execution duration: \(totalElapsedDurationInMilliseconds.milliseconds)ms"
            )
        }
    }
}

extension FeaturevisorCLI.Test {

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

        // TODO: We need to cut off the extension
        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {
            return false
        }

        return feature.tags.contains(where: tags.contains)
    }

    // If feature is exposed for iOS or tvOS then it doesn't matter which datafile e.g. ios or tvos we use
    func firstTagToVerifyAgainst(
        tags: [Feature.Tag],
        environment: Environment,
        featureKey: String,
        in features: [Feature]
    ) -> Feature.Tag {

        return tags.first(where: {
            isFeatureSupported(by: [$0], featureKey: featureKey, in: features)
                && isFeatureExposed(
                    for: [$0],
                    under: environment.rawValue,
                    featureKey: featureKey,
                    in: features
                )
        })!  // TODO: Deal with force unwrap, redesign the way how we iterate the test suit
    }

    func isFeatureExposed(
        for tags: [Feature.Tag],
        under environment: String,
        featureKey: String,
        in features: [Feature]
    ) -> Bool {

        // TODO: We need to cut off the extension
        guard let feature = features.first(where: { $0.key == "\(featureKey).yml" }) else {
            return false
        }

        let supportedTag = tags.first(where: { tag in
            feature.environments[environment]?.isExposed(for: tag) ?? false  // TODO: Handle it
        })

        return supportedTag != nil
    }
}
