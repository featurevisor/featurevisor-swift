import Foundation

extension UInt64 {

    var milliseconds: Double {
        let elapsedTimeInMilliSeconds = Double(self) / 1_000_000.0
        return Double(elapsedTimeInMilliSeconds)
    }

    var seconds: Double {
        let elapsedTimeInMilliSeconds = Double(self) / 1_000_000_000.0
        return Double(elapsedTimeInMilliSeconds)
    }
}
