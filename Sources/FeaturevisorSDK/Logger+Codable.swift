import Foundation

extension Logger {

    func debug<T: Codable>(_ message: LogMessage, _ object: T) {
        Task { [weak self] in
            let logDetails: LogDetails? = await self?.toLogDetails(object)
            self?.log(level: .debug, message: message, details: logDetails)
        }
    }

    func info<T: Codable>(_ message: LogMessage, _ object: T) {
        Task { [weak self] in
            let logDetails: LogDetails? = await self?.toLogDetails(object)
            self?.log(level: .info, message: message, details: logDetails)
        }
    }

    func warn<T: Codable>(_ message: LogMessage, _ object: T) {
        Task { [weak self] in
            let logDetails: LogDetails? = await self?.toLogDetails(object)
            self?.log(level: .warn, message: message, details: logDetails)
        }
    }

    func error<T: Codable>(_ message: LogMessage, _ object: T) {
        Task { [weak self] in
            let logDetails: LogDetails? = await self?.toLogDetails(object)
            self?.log(level: .error, message: message, details: logDetails)
        }
    }
}

extension Logger {

    fileprivate func toLogDetails<T: Codable>(_ object: T) async -> LogDetails? {
        guard let data = try? JSONEncoder().encode(object) else {
            return nil
        }

        guard
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        else {
            return nil
        }

        return dictionary as? LogDetails
    }
}
