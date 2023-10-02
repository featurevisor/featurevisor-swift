import FeaturevisorTypes
import Foundation

public extension FeaturevisorInstance {
    
    // MARK: - Variable

    func getVariable(
            featureKey: FeatureKey,
            variableKey: VariableKey,
            context: Context = [:]) ->  VariableValue? {
        let evaluation = evaluateVariable(featureKey: featureKey, variableKey: variableKey, context: context)

        guard let variableValue = evaluation.variableValue else {
            return nil
        }

        return variableValue
    }
    func getVariableBoolean(
            featureKey: FeatureKey,
            variableKey: VariableKey,
            context: Context) -> Bool? {
        return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Bool
    }

    func getVariableString(
            featureKey: FeatureKey,
            variableKey: VariableKey,
            context: Context) ->  String? {
        return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? String
    }

    func getVariableInteger(
            featureKey: FeatureKey,
            variableKey: VariableKey,
            context: Context) ->  Int? {
        return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Int
    }

    func getVariableDouble(
            featureKey: FeatureKey,
            variableKey: VariableKey,
            context: Context) -> Double? {
        return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Double
    }

    func getVariableArray(
            featureKey: FeatureKey,
            variableKey: String,
            context: Context) -> [String]? {
        return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? [String]
    }

    func getVariableObject<T: Decodable>(
            featureKey: FeatureKey,
            variableKey: String,
            context: Context) -> T? {

        let object = getVariable(
                featureKey: featureKey,
                variableKey: variableKey,
                context: context)?.value as? VariableObjectValue

        guard let data = try? JSONEncoder().encode(object) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    func getVariableJSON<T: Decodable>(
            featureKey: FeatureKey,
            variableKey: String,
            context: Context) -> T? {

        guard let json = getVariable(
                featureKey: featureKey,
                variableKey: variableKey,
                context: context)?.value as? String else {
            return nil
        }

        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }
    
}
