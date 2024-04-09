import Foundation

extension TimeInterval {
    /// Creates a new `TimeInterval` from the given number of nanoseconds.
    /// - Parameter nanoseconds: The number of nanoseconds.
    public init(nanoseconds: Double) { self = nanoseconds / 1_000_000_000 }

    /// Creates a new `TimeInterval` from the given number of microseconds.
    /// - Parameter microseconds: The number of microseconds.
    public init(microseconds: Double) { self = microseconds / 1_000_000 }

    /// Creates a new `TimeInterval` from the given number of milliseconds.
    /// - Parameter milliseconds: The number of milliseconds.
    public init(milliseconds: Double) { self = milliseconds / 1_000 }

    /// Creates a new `TimeInterval` from the given number of seconds.
    /// - Parameter seconds: The number of seconds.
    public init(seconds: Double) { self = seconds }

    /// Creates a new `TimeInterval` from the given number of minutes.
    /// - Parameter minutes: The number of minutes.
    public init(minutes: Double) { self = minutes * 60 }

    /// Creates a new `TimeInterval` from the given number of hours.
    /// - Parameter hours: The number of hours.
    public init(hours: Double) { self = hours * 3_600 }

    /// The number of nanoseconds in the `TimeInterval`.
    public var nanoseconds: Double { self * 1_000_000_000 }

    /// The number of microseconds in the `TimeInterval`.
    public var microseconds: Double { self * 1_000_000 }

    /// The number of milliseconds in the `TimeInterval`.
    public var milliseconds: Double { self * 1_000 }

    /// The number of seconds in the `TimeInterval`.
    public var seconds: Double { self }

    /// The number of minutes in the `TimeInterval`.
    public var minutes: Double { self / 60 }

    /// The number of hours in the `TimeInterval`.
    public var hours: Double { self / 3_600 }
}
