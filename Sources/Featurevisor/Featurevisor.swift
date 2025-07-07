import ArgumentParser
import Commands
import FeaturevisorSDK
import FeaturevisorTypes
import Files
import Foundation
import Yams

@main
struct Featurevisor: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "Featurevisor CLI.",
        subcommands: [Benchmark.self, Evaluate.self, Test.self]
    )
}

extension Featurevisor {

    struct Benchmark: AsyncParsableCommand {

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

        mutating func run() async throws {

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

extension Featurevisor {

    struct Evaluate: AsyncParsableCommand {

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

        mutating func run() async throws {

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

extension Featurevisor {

    struct Test: AsyncParsableCommand {

        static let configuration = CommandConfiguration(
            abstract:
                "We can write test specs in the same expressive way as we defined our features to test against Featurevisor Swift SDK.",
            subcommands: [Benchmark.self]
        )

        @Argument(help: "The path to features test directory.")
        var featuresTestDirectoryPath: String

        @Option(
            help:
                "The option is used to specify the feature key which will be used for testing."
        )
        var feature: String?

        @Flag(help: "If you are interested to see only the test specs that fail.")
        var onlyFailures = false

        mutating func run() async throws {

            let startTime = DispatchTime.now()

            // Run Featurevisor CLI to build the datafiles
            // TODO: Handle better, react on errors etc.
            Commands.Task.run("bash -c cd \(featuresTestDirectoryPath) && npx featurevisor build")

            var testSuits = try loadAllFeatureTestSuits(
                featuresTestDirectoryPath: featuresTestDirectoryPath
            )

            if let feature {
                testSuits = testSuits.filter { $0.feature == feature }
            }

            let features = try loadAllFeatures(featuresTestDirectoryPath: featuresTestDirectoryPath)

            var totalTestSpecs = 0
            var failedTestSpecs = 0

            var totalAssertionsCount = 0
            var failedAssertionsCount = 0

            let datafileProvider = DatafileProvider(
                featuresTestDirectoryPath: self.featuresTestDirectoryPath
            )

            let suiteResults = try await withThrowingTaskGroup(of: TestSuiteResult.self) { group in

                let onlyFailures = self.onlyFailures

                for testSuit in testSuits {
                    group.addTask {
                        try await Featurevisor.Test.runTestSuite(
                            testSuit: testSuit,
                            features: features,
                            datafileProvider: datafileProvider,
                            onlyFailures: onlyFailures
                        )
                    }
                }

                return try await group.reduce(into: [TestSuiteResult]()) { $0.append($1) }
            }

            for suite in suiteResults {
                totalAssertionsCount += suite.assertions
                failedAssertionsCount += suite.failedAssertions

                totalTestSpecs += 1

                if suite.isFailing {
                    failedTestSpecs += 1
                }
            }

            let endTime = DispatchTime.now()
            let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

            print(
                "\nTest specs: \(totalTestSpecs - failedTestSpecs) passed, \(failedTestSpecs) failed"
            )
            print(
                "Assertions: \(totalAssertionsCount - failedAssertionsCount) passed, \(failedAssertionsCount) failed"
            )

            print(String(format: "Time: %.2fs", elapsedTime.seconds))
        }
    }
}

extension Featurevisor.Test {

    struct TestSuiteResult {
        let assertions: Int
        let failedAssertions: Int
        let elapsedTime: UInt64
        let isFailing: Bool
        let output: String?
    }

    static func runTestSuite(
        testSuit: FeatureTestSuitFile,
        features: [Feature],
        datafileProvider: DatafileProvider,
        onlyFailures: Bool
    ) async throws -> TestSuiteResult {

        guard
            Featurevisor.Test.isFeatureSupported(
                by: [.ios, .tvos],
                featureKey: testSuit.feature,
                in: features
            )
        else {
            return TestSuiteResult(
                assertions: 0,
                failedAssertions: 0,
                elapsedTime: 0,
                isFailing: false,
                output: nil
            )
        }

        let outputBuilder = FeatureResultOutputBuilder(
            feature: testSuit.feature,
            onlyFailures: onlyFailures
        )

        var failedAssertions = 0
        var totalElapsed: UInt64 = 0

        let results = try await withThrowingTaskGroup(of: AssertionResult.self) { group in
            for (index, testCase) in testSuit.assertions.enumerated() {
                group.addTask {
                    return try await Featurevisor.Test.evaluateAssertion(
                        index: index,
                        testCase: testCase,
                        testSuit: testSuit,
                        features: features,
                        datafileProvider: datafileProvider
                    )
                }
            }

            return try await group.reduce(into: [AssertionResult]()) { $0.append($1) }
        }

        for result in results {
            if !result.success {
                failedAssertions += 1
            }
            totalElapsed += result.elapsedTime
            outputBuilder.addAssertion(result)
        }

        let output = outputBuilder.build()

        if let output {
            print(output)
        }

        return TestSuiteResult(
            assertions: testSuit.assertions.count,
            failedAssertions: failedAssertions,
            elapsedTime: totalElapsed,
            isFailing: failedAssertions > 0,
            output: output
        )
    }

}

extension Featurevisor.Test {

    struct AssertionResult {
        let success: Bool
        let elapsedTime: UInt64
        let environment: Environment
        let index: Int
        let expectedValueFailures: [VariableKey: (expected: VariableValue, got: VariableValue?)]
        let description: String?
    }

    static func evaluateAssertion(
        index: Int,
        testCase: Assertion,
        testSuit: FeatureTestSuitFile,
        features: [Feature],
        datafileProvider: DatafileProvider
    ) async throws -> AssertionResult {
        var sdks: [Feature.Tag: [Environment: FeaturevisorInstance]] = [:]

        for tag in [Feature.Tag.ios, Feature.Tag.tvos] {
            let sdkProduction = try SDKProvider.provide(
                for: datafileProvider.all[tag]![.production]!,
                assertionAt: testCase.at
            )

            let sdkStaging = try SDKProvider.provide(
                for: datafileProvider.all[tag]![.staging]!,
                assertionAt: testCase.at
            )

            sdks[tag] = [
                .staging: sdkStaging,
                .production: sdkProduction,
            ]
        }

        let environment = testCase.environment
        let context = testCase.context ?? [:]
        let tag = firstTagToVerifyAgainst(
            tags: [.ios, .tvos],
            environment: environment,
            featureKey: testSuit.feature,
            in: features
        )

        guard
            Featurevisor.Test.isFeatureExposed(
                for: [.ios, .tvos],
                under: environment.rawValue,
                featureKey: testSuit.feature,
                in: features
            )
        else {
            return AssertionResult(
                success: true,
                elapsedTime: 0,
                environment: environment,
                index: index,
                expectedValueFailures: [:],
                description: testCase.description
            )
        }

        let sdk = sdks[tag]![environment]!

        let startTime = DispatchTime.now()

        let isFeatureEnabled =
            sdk.isEnabled(featureKey: testSuit.feature, context: context)
            == testCase.expectedToBeEnabled

        var expectedValueFailures: [VariableKey: (expected: VariableValue, got: VariableValue?)] =
            [:]

        if let expectedVariables = testCase.expectedVariables {
            for (key, expectedValue) in expectedVariables {
                let actual = sdk.getVariable(
                    featureKey: testSuit.feature,
                    variableKey: key,
                    context: context
                )
                if actual != expectedValue {
                    expectedValueFailures[key] = (expected: expectedValue, got: actual)
                }
            }
        }

        let endTime = DispatchTime.now()
        let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

        let success = isFeatureEnabled && expectedValueFailures.isEmpty

        return AssertionResult(
            success: success,
            elapsedTime: elapsedTime,
            environment: environment,
            index: index,
            expectedValueFailures: expectedValueFailures,
            description: testCase.description
        )
    }
}

extension Featurevisor.Test {

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

    static func isFeatureSupported(
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
    static func firstTagToVerifyAgainst(
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
        }) ?? .ios  // TODO: Deal with fallback, redesign the way how we iterate the test suit
    }

    static func isFeatureExposed(
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
