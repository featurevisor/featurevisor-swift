public enum EventName {
    case ready
    case refresh
    case update
    case activation
    case datafileFetchError
}

public typealias Listener = (@escaping (Any...) -> Void) -> Void

public typealias Listeners = [EventName: [Listener]]

public class Emitter {
    var listeners: Listeners = [:]

    public func addListener(_ eventName: EventName, _ listener: @escaping Listener) {
        if self.listeners[eventName] == nil {
            self.listeners[eventName] = []
        }

        self.listeners[eventName]?.append(listener)
    }

    public func removeListener(_ eventName: EventName, _ listener: Listener) {
        if let listeners = self.listeners[eventName] {
            self.listeners[eventName] = listeners.filter({
                $0 as AnyObject !== listener as AnyObject
            })
        }
    }

    public func removeAllListeners(_ eventName: EventName?) {
        if let eventName = eventName {
            self.listeners[eventName] = []
        }
        else {
            self.listeners = [:]
        }
    }

    public func emit(_ eventName: EventName, _ args: Any...) {
        if let listeners = self.listeners[eventName] {
            for listener in listeners {
                listener({
                    (args: Any...) -> Void in
                })
            }
        }
    }
}
