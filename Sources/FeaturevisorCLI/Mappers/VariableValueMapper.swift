import FeaturevisorTypes
import Foundation

enum VariableValueMapper {

    static func map(from expectedValues: [ExpectedVariableKey: ExpectedVariableValue]?)
        -> [VariableKey: VariableValue]?
    {
        guard let expectedValues else {
            return nil
        }

        var newDictionary: [VariableKey: VariableValue] = [:]

        expectedValues.forEach({ (key, value) in
            var variableValue: VariableValue

            switch value {
                case .array(let array):
                    variableValue = .array(array)
                case .boolean(let boolean):
                    variableValue = .boolean(boolean)
                case .double(let double):
                    variableValue = .double(double)
                case .integer(let interger):
                    variableValue = .integer(interger)
                case .json(let json):
                    variableValue = .json(json)
                case .object(let object):
                    variableValue = .object(map(from: object) ?? [:])
                case .string(let string):
                    variableValue = .string(string)
            }

            newDictionary[key] = variableValue
        })

        return newDictionary
    }
}
