import FeaturevisorTypes
import Foundation

struct Semver: Equatable {
    let version: String
    let major: Int
    let minor: Int
    let patch: Int

    init(_ version: String) {
        self.version = version
        let components = version.components(separatedBy: ".")
        major = Int(components[0]) ?? 0
        minor = components.count > 1 ? Int(components[1]) ?? 0 : 0
        patch = components.count > 2 ? Int(components[2]) ?? 0 : 0
    }

    static func == (lhs: Semver, rhs: Semver) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }

    static func != (lhs: Semver, rhs: Semver) -> Bool {
        return !(lhs == rhs)
    }

    static func > (lhs: Semver, rhs: Semver) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major > rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor > rhs.minor
        }
        return lhs.patch > rhs.patch
    }

    static func >= (lhs: Semver, rhs: Semver) -> Bool {
        return lhs == rhs || lhs > rhs
    }

    static func < (lhs: Semver, rhs: Semver) -> Bool {
        return !(lhs >= rhs)
    }

    static func <= (lhs: Semver, rhs: Semver) -> Bool {
        return !(lhs > rhs)
    }
}
