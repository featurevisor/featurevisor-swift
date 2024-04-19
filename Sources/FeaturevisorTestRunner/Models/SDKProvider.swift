import FeaturevisorSDK
import FeaturevisorTypes
import Foundation

enum SDKProvider {

    enum DatafileConfig {
        private static let productionDatafilePath = "/dist/production/datafile-tag-${{ tag }}.json"
        private static let stagingDatafilePath = "/dist/staging/datafile-tag-${{ tag }}.json"

        static func relevantPath(for tag: Feature.Tag, under environment: Environment) -> String {
            switch environment {
                case .production:
                    return productionDatafilePath.replacingOccurrences(
                        of: "${{ tag }}",
                        with: tag.rawValue
                    )  // TODO: Make replace placeholder prettier
                case .staging:
                    return stagingDatafilePath.replacingOccurrences(
                        of: "${{ tag }}",
                        with: tag.rawValue
                    )  // TODO: Make replace placeholder prettier
            }
        }
    }

    private static let maxBucketedNumber = 100000.0

    static func provide(
        for tag: Feature.Tag,
        under environment: Environment,
        using path: String,
        assertionAt: Double
    ) throws -> FeaturevisorInstance {

        let datafileJSON = try String(
            contentsOfFile: path + DatafileConfig.relevantPath(for: tag, under: environment),
            encoding: .utf8
        )

        let datafileContent = try JSONDecoder()
            .decode(DatafileContent.self, from: datafileJSON.data(using: .utf8)!)

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
