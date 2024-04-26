import Commands
import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

extension FeaturevisorTestRunner.Evaluate {

    func evaluateFeature(options: Options) {

        // TODO: Handle this better
        Commands.Task.run("bash -c featurevisor build")

        let f = try! SDKProvider.provide(
            for: .ios,
            under: options.environment,
            using: ".",
            assertionAt: 1
        )

        let flagEvaluation = f.evaluateFlag(featureKey: options.feature, context: options.context)
        let variationEvaluation = f.evaluateVariation(
            featureKey: options.feature,
            context: options.context
        )

        var variableEvaluations: [VariableKey: Evaluation] = [:]
        let feature = f.getFeature(byKey: options.feature)

        feature?.variablesSchema
            .forEach({ variableSchema in
                let variableEvaluation = f.evaluateVariable(
                    featureKey: options.feature,
                    variableKey: variableSchema.key,
                    context: options.context
                )

                variableEvaluations[variableSchema.key] = variableEvaluation
            })

        print(
            "Evaluating feature \(options.feature) in environment \(options.environment.rawValue)..."
        )
        print("Against context: \(options.context)")  // TODO: pretty

        // flag
        printHeader("Is enabled?")

        print("Value: \(flagEvaluation.enabled ?? false)")
        print("\nDetails:\n")

        printEvaluationDetails(flagEvaluation)

        // variation
        printHeader("Variation")

        if let variation = variationEvaluation.variation {
            print("Value: \(variation.value)")

            print("\nDetails:\n")

            printEvaluationDetails(variationEvaluation)
        }
        else {
            print("No variations defined.")
        }

        // variables
        if !variableEvaluations.isEmpty {
            variableEvaluations.forEach({ variableKey, evaluation in
                printHeader("Variable: \(variableKey)")

                if let variableValue = evaluation.variableValue {
                    print("Value: \(variableValue)")
                }
                else {
                    print("Value: nil")
                }

                print("\nDetails:\n")

                printEvaluationDetails(evaluation)
            })
        }
        else {
            printHeader("Variables")
            print("No variables defined.")
        }
    }
}

extension FeaturevisorTestRunner.Evaluate {

    fileprivate func printHeader(_ message: String) {
        print("\n\n###############")
        print(" \(message)")
        print("###############\n")
    }

    fileprivate func printEvaluationDetails(_ evaluation: Evaluation) {

        if let variation = evaluation.variation {
            print("- variation: \(variation.value)")
        }

        if let variableSchema = evaluation.variableSchema {
            print("- variableType: \(variableSchema.type)")
            print("- defaultValue: \(variableSchema.defaultValue)")
        }

        print(evaluation)
    }
}
