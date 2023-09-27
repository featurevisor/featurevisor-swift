import Foundation

public enum FeaturevisorError: Error, Equatable {

    /// Thrown when receiving unparseable Datafile JSON responses.
    /// - Parameters:
    ///   - data: The data being parsed.
    ///   - errorMessage: The message from the error which occured during parsing.
    case unparseableJSON(data: Data?, errorMessage: String)
    
    /// Thrown when attempting to construct an invalid URL.
    /// - Parameter string: The invalid URL string.
    case invalidURL(string: String)
    
    case downloadingDatafile(String)
}

extension FeaturevisorError: LocalizedError {
    
    private var errorPrefix: String {
        return "Featurevisor SDK"
    }
    
    public var errorDescription: String? {
        switch self {
            case .downloadingDatafile(let datafileUrl):
            return "\(errorPrefix) was not able to download the data file at: \(datafileUrl)"
            case .invalidURL(let urlString):
            return "\(errorPrefix) was not able to parse following url '\(urlString)'"
            case .unparseableJSON(_, let errorMessage):
            return "\(errorPrefix) was not able to parse JSON response '\(errorMessage)'"
        }
    }
}
