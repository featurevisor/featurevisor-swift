import FeaturevisorTypes
import Foundation

extension FeaturevisorInstance {

    // MARK: - Variable

    public func getVariable(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context = [:]
    ) -> VariableValue? {
        let evaluation = evaluateVariable(
            featureKey: featureKey,
            variableKey: variableKey,
            context: context
        )

        guard let variableValue = evaluation.variableValue else {
            return nil
        }

        return variableValue
    }
    public func getVariableBoolean(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context
    ) -> Bool? {
        return
            getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value
            as? Bool
    }

    public func getVariableString(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context
    ) -> String? {
        return
            getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value
            as? String
    }

    public func getVariableInteger(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context
    ) -> Int? {
        return
            getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value
            as? Int
    }

    public func getVariableDouble(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context
    ) -> Double? {
        return
            getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value
            as? Double
    }

    public func getVariableArray(
        featureKey: FeatureKey,
        variableKey: String,
        context: Context
    ) -> [String]? {
        return
            getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value
            as? [String]
    }

    public func getVariableObject(
        featureKey: FeatureKey,
        variableKey: String,
        context: Context
    ) -> VariableObjectValue? {

        return
            getVariable(
                featureKey: featureKey,
                variableKey: variableKey,
                context: context
            )?
            .value as? VariableObjectValue
    }

    public func getVariableJSON<T: Decodable>(
        featureKey: FeatureKey,
        variableKey: String,
        context: Context
    ) -> T? {

        guard
            let json =
                getVariable(
                    featureKey: featureKey,
                    variableKey: variableKey,
                    context: context
                )?
                .value as? String
        else {
            return nil
        }

        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

}
