public enum LogLevel: String {
    case error
    case warn
    case info
    case debug
}

public typealias LogMessage = String

public typealias LogDetails = [String: Any]

public typealias LogHandler = (LogLevel, LogMessage, LogDetails?) -> Void

public let defaultLogLevels: [LogLevel] = [
    .error,
    .warn,
]

public let defaultLogHandler: LogHandler = { level, message, details in
    print("[\(level.rawValue)] \(message)")
}

public class Logger {
    var levels: [LogLevel]
    let handle: LogHandler

    public init(levels: [LogLevel], handle: @escaping LogHandler) {
        self.levels = levels
        self.handle = handle
    }

    public func setLevels(levels: [LogLevel]) {
        self.levels = levels
    }

    public func log(level: LogLevel, message: LogMessage, details: LogDetails? = nil) {
        if self.levels.contains(level) {
            self.handle(level, message, details)
        }
    }

    public func debug(_ message: LogMessage, _ details: LogDetails? = nil) {
        self.log(level: .debug, message: message, details: details)
    }

    public func info(_ message: LogMessage, _ details: LogDetails? = nil) {
        self.log(level: .info, message: message, details: details)
    }

    public func warn(_ message: LogMessage, _ details: LogDetails? = nil) {
        self.log(level: .warn, message: message, details: details)
    }

    public func error(_ message: LogMessage, _ details: LogDetails? = nil) {
        self.log(level: .error, message: message, details: details)
    }
}

public func createLogger(
    levels: [LogLevel] = defaultLogLevels,
    handle: @escaping LogHandler = defaultLogHandler
) -> Logger {
    return Logger(levels: levels, handle: handle)
}
