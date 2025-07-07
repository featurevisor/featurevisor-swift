import FeaturevisorTypes
import Foundation

class DatafileProvider {

    typealias Tag = Feature.Tag

    enum DatafileConfig {
        private static let productionDatafilePath = "/dist/production/datafile-tag-${{ tag }}.json"
        private static let stagingDatafilePath = "/dist/staging/datafile-tag-${{ tag }}.json"

        static func relevantPath(for tag: Tag, under environment: Environment) -> String {
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

    var all: [Tag: [Environment: DatafileContent]] = [:]

    init(featuresTestDirectoryPath: String) {
        all[.ios] = [
            .staging: try! DatafileProvider.datafile(
                for: .ios,
                path: featuresTestDirectoryPath,
                environment: .staging
            ),

            .production: try! DatafileProvider.datafile(
                for: .ios,
                path: featuresTestDirectoryPath,
                environment: .production
            ),
        ]

        all[.tvos] = [
            .staging: try! DatafileProvider.datafile(
                for: .tvos,
                path: featuresTestDirectoryPath,
                environment: .staging
            ),

            .production: try! DatafileProvider.datafile(
                for: .tvos,
                path: featuresTestDirectoryPath,
                environment: .production
            ),
        ]
    }

    static func datafile(
        for tag: Feature.Tag,
        path featuresPath: String,
        environment: Environment
    ) throws -> DatafileContent {

        let datafileJSON = try String(
            contentsOfFile: featuresPath
                + DatafileConfig.relevantPath(for: tag, under: environment),
            encoding: .utf8
        )

        return try JSONDecoder()
            .decode(DatafileContent.self, from: datafileJSON.data(using: .utf8)!)
    }
}
