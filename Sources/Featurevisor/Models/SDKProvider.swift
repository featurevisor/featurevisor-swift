import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

enum SDKProvider {

    private static let maxBucketedNumber = 100000.0

    static func provide(
        for datafileContent: DatafileContent,
        assertionAt: Double
    ) throws -> FeaturevisorInstance {

        var options = InstanceOptions.default
        options.datafile = datafileContent
        options.configureBucketValue = { _, _, _ -> BucketValue in
            return Int(assertionAt * (maxBucketedNumber / 100.0))
        }
        options.logger = Logger(levels: []) { _, _, _ in
        }

        return try FeaturevisorSDK.createInstance(options: options)
    }
}
