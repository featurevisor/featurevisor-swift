import Foundation

extension FeaturevisorInstance {

    // MARK: - Statuses

    public func isReady() -> Bool {
        return statuses.ready
    }

}
