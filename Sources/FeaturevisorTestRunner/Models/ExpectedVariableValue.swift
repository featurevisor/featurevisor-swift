import FeaturevisorTypes
import Foundation

typealias ExpectedVariableKey = String
typealias ExpectedVariableObjectValue = [ExpectedVariableKey: ExpectedVariableValue]

enum ExpectedVariableValue: Codable {
    case boolean(Bool)
    case string(String)
    case integer(Int)
    case double(Double)
    case array([String])
    case object(ExpectedVariableObjectValue)
    case json(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        }
        else if let integerString = try? container.decode(String.self),
            let integer = Int(integerString)
        {
            self = .integer(integer)
        }
        else if let doubleString = try? container.decode(String.self),
            let double = Double(doubleString)
        {
            self = .double(double)
        }
        else if let array = try? container.decodeStringified([String].self) {
            self = .array(array)
        }
        else if let string = try? container.decodeStringified(String.self) {

            guard let data = string.data(using: .utf8),
                let _ = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            else {
                self = .string(string)
                return
            }

            self = .json(string)
        }
        else if let object = try? container.decode(ExpectedVariableObjectValue.self) {
            self = .object(object)
        }
        else {
            let context = DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "\(VariableValue.self) unknown"
            )
            debugPrint("ERROR: \(decoder.codingPath)")
            throw DecodingError.dataCorrupted(context)
        }
    }
}
