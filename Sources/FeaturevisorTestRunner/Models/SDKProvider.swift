import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

enum SDKProvider {

    private static let config: [Environment: String] = [
        .production: "/dist/production/datafile-tag-ios.json",
        .staging: "/dist/staging/datafile-tag-ios.json",
    ]
    
    private static let maxBucketedNumber = 100000.0

    static func provide(
        for environment: Environment,
        using path: String,
        assertionAt: Double
    ) throws -> FeaturevisorInstance {

        let datafileJSON = try String(contentsOfFile: path + config[environment]!, encoding: .utf8)
        let datafileContent = try JSONDecoder()
            .decode(DatafileContent.self, from: datafileJSON.data(using: .utf8)!)

        var options = InstanceOptions.default
        options.datafile = datafileContent
        options.configureBucketValue = { _, _, _ -> BucketValue in
            return Int(assertionAt * (maxBucketedNumber / 100.0))
        }

        return try FeaturevisorSDK.createInstance(options: options)
    }
}
