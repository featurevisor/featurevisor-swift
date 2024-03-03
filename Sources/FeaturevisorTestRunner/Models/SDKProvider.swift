import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

enum SDKProvider {

    private static let config: [Environment: String] = [
        .production: "/dist/production/datafile-tag-ios.json",
        .staging: "/dist/staging/datafile-tag-ios.json",
    ]

    static func provide(
        for environment: Environment,
        using path: String
    ) throws -> FeaturevisorInstance {

        let datafileJSON = try String(contentsOfFile: path + config[environment]!, encoding: .utf8)
        let datafileContent = try JSONDecoder()
            .decode(DatafileContent.self, from: datafileJSON.data(using: .utf8)!)

        var options = InstanceOptions.default
        options.datafile = datafileContent

        return try FeaturevisorSDK.createInstance(options: options)
    }
}
