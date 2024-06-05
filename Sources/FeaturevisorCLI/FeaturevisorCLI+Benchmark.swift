import Commands
import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

extension FeaturevisorCLI.Benchmark {

    func benchmarkFeature(options: Options) {

        print("Running benchmark for feature \(options.feature)...")

        print("Building datafile containing all features for \(options.environment)...")

        let datafileBuildStart = DispatchTime.now()

        // TODO: Handle this better
        Commands.Task.run("bash -c featurevisor build")

        let datafileBuildEnd = DispatchTime.now()
        let datafileBuildDuration = TimeInterval(
            nanoseconds: Double(
                datafileBuildEnd.uptimeNanoseconds - datafileBuildStart.uptimeNanoseconds
            )
        )

        print("Datafile build duration: \(datafileBuildDuration.seconds)s")

        let f = try! SDKProvider.provide(
            for: .ios,
            under: options.environment,
            using: ".",
            assertionAt: 1
        )

        print("...SDK initialized")

        print("Against context: \(options.context)")

        let output: Output

        if let variable = options.variable {
            print("Evaluating variable \(variable) \(options.n) times...")

            output = benchmarkFeatureVariable(
                f,
                featureKey: options.feature,
                variableKey: variable,
                context: options.context,
                n: options.n
            )
        }
        else if options.variation {
            print("Evaluating variation \(options.n) times...")

            output = benchmarkFeatureVariation(
                f,
                feature: options.feature,
                context: options.context,
                n: options.n
            )
        }
        else {
            print("Evaluating flag \(options.n) times...")

            output = benchmarkFeatureFlag(
                f,
                feature: options.feature,
                context: options.context,
                n: options.n
            )
        }

        print("Evaluated value : \(String(describing: output.value))")
        print("Total duration  : \(output.duration.milliseconds)ms")
        print("Average duration: \((output.duration / Double(options.n)).milliseconds)ms")
    }
}

extension FeaturevisorCLI.Benchmark {

    func benchmarkFeatureFlag(
        _ f: FeaturevisorInstance,
        feature: FeatureKey,
        context: [AttributeKey: AttributeValue],
        n: Int
    ) -> Output {

        let start = DispatchTime.now()
        var value: Any = false

        for _ in 0...n {
            value = f.isEnabled(featureKey: feature, context: context)
        }

        let end = DispatchTime.now()

        return .init(
            value: value,
            duration: TimeInterval(
                nanoseconds: Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
            )
        )
    }

    func benchmarkFeatureVariation(
        _ f: FeaturevisorInstance,
        feature: FeatureKey,
        context: [AttributeKey: AttributeValue],
        n: Int
    ) -> Output {

        let start = DispatchTime.now()
        var value: VariationValue? = nil

        for _ in 0...n {
            value = f.getVariation(featureKey: feature, context: context)
        }

        let end = DispatchTime.now()

        return .init(
            value: value,
            duration: TimeInterval(
                nanoseconds: Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
            )
        )
    }

    func benchmarkFeatureVariable(
        _ f: FeaturevisorInstance,
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: [AttributeKey: AttributeValue],
        n: Int
    )
        -> Output
    {
        let start = DispatchTime.now()
        var value: VariableValue?

        for _ in 0...n {
            value = f.getVariable(featureKey: feature, variableKey: variableKey, context: context)
        }

        let end = DispatchTime.now()

        return .init(
            value: value,
            duration: TimeInterval(
                nanoseconds: Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
            )
        )
    }
}
