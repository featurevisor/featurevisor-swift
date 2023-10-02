import Foundation

public extension FeaturevisorInstance {

    // MARK: - Statuses

    func isReady() -> Bool {
        return statuses.ready
    }

}
