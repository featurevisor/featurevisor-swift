import Foundation

public enum FeaturevisorError: Error, Equatable {

    /// Thrown when receiving unparseable Datafile JSON responses.
    /// - Parameters:
    ///   - data: The data being parsed.
    ///   - errorMessage: The message from the error which occured during parsing.
    case unparseableDatafileJSON(data: Data?, errorMessage: String)
    
    case missingDatafileOptions
    case downloadingDatafile(String)
}

extension FeaturevisorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .missingDatafileOptions:
                return
                    "Featurevisor SDK instance cannot be created without both `datafile` and `datafileUrl` options"
            case .downloadingDatafile(let datafileUrl):
                return "Featurevisor SDK was not able to download the data file at: \(datafileUrl)"
            case .unparseableDatafileJSON(_, let errorMessage):
                return errorMessage
        }
    }
}
