import FeaturevisorTypes
import Foundation

public typealias ConfigureBucketKey = (Feature, Context, BucketKey) -> BucketKey
public typealias ConfigureBucketValue = (Feature, Context, BucketValue) -> BucketValue
public typealias InterceptContext = (Context) -> Context
public typealias DatafileFetchHandler = (_ datafileURL: URL) async -> Result<DatafileContent, Error>

public struct Statuses {
    public var ready: Bool
    public var refreshInProgress: Bool
}

public enum EvaluationReason: String {
    case notFound = "not_found"
    case noVariations = "no_variations"
    case disabled
    case required
    case outOfRange = "out_of_range"
    case forced
    case initial
    case sticky
    case rule
    case allocated
    case defaulted
    case override
    case error
}

public struct Evaluation: Codable {

    private enum CodingKeys: String, CodingKey {
        case featureKey
        case reason
        case bucketKey
        case bucketValue
        case ruleKey
        case error
        case enabled
        case forceIndex
        case force
        case traffic
        case sticky
        case initial
        case variation
        case variationValue
        case variableKey
        case variableValue
        case variableSchema
    }

    // required
    public let featureKey: FeatureKey
    public let reason: EvaluationReason

    // common
    public let bucketKey: BucketKey?
    public let bucketValue: BucketValue?
    public let ruleKey: RuleKey?
    public let enabled: Bool?
    public let traffic: Traffic?
    public let forceIndex: Int?
    public let force: Force?
    public let sticky: OverrideFeature?
    public let initial: OverrideFeature?

    // variation
    public let variation: Variation?
    public let variationValue: VariationValue?

    // variable
    public let variableKey: VariableKey?
    public let variableValue: VariableValue?
    public let variableSchema: VariableSchema?

    public init(
        featureKey: FeatureKey,
        reason: EvaluationReason,
        bucketKey: BucketKey? = nil,
        bucketValue: BucketValue? = nil,
        ruleKey: RuleKey? = nil,
        enabled: Bool? = nil,
        traffic: Traffic? = nil,
        forceIndex: Int? = nil,
        force: Force? = nil,
        sticky: OverrideFeature? = nil,
        initial: OverrideFeature? = nil,
        variation: Variation? = nil,
        variationValue: VariationValue? = nil,
        variableKey: VariableKey? = nil,
        variableValue: VariableValue? = nil,
        variableSchema: VariableSchema? = nil
    ) {
        self.featureKey = featureKey
        self.reason = reason
        self.bucketKey = bucketKey
        self.bucketValue = bucketValue
        self.ruleKey = ruleKey
        self.enabled = enabled
        self.traffic = traffic
        self.forceIndex = forceIndex
        self.force = force
        self.sticky = sticky
        self.initial = initial
        self.variation = variation
        self.variationValue = variationValue
        self.variableKey = variableKey
        self.variableValue = variableValue
        self.variableSchema = variableSchema
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(featureKey, forKey: .featureKey)
        try container.encode(reason.rawValue, forKey: .reason)
        try container.encodeIfPresent(bucketKey, forKey: .bucketKey)
        try container.encodeIfPresent(bucketValue, forKey: .bucketValue)
        try container.encodeIfPresent(ruleKey, forKey: .ruleKey)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(forceIndex, forKey: .forceIndex)
        try container.encodeIfPresent(force, forKey: .force)
        try container.encodeIfPresent(traffic, forKey: .traffic)
        try container.encodeIfPresent(sticky, forKey: .sticky)
        try container.encodeIfPresent(initial, forKey: .initial)
        try container.encodeIfPresent(variation, forKey: .variation)
        try container.encodeIfPresent(variationValue, forKey: .variationValue)
        try container.encodeIfPresent(variableKey, forKey: .variableKey)
        try container.encodeIfPresent(variableValue, forKey: .variableValue)
        try container.encodeIfPresent(variableSchema, forKey: .variableSchema)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        featureKey = try container.decode(FeatureKey.self, forKey: .featureKey)
        reason =
            try EvaluationReason(rawValue: container.decode(String.self, forKey: .reason)) ?? .error
        bucketKey = try container.decodeIfPresent(BucketKey.self, forKey: .bucketKey)
        bucketValue = try container.decodeIfPresent(BucketValue.self, forKey: .bucketValue)
        ruleKey = try? container.decodeIfPresent(RuleKey.self, forKey: .ruleKey)
        enabled = try? container.decodeIfPresent(Bool.self, forKey: .enabled)
        forceIndex = try? container.decodeIfPresent(Int.self, forKey: .forceIndex)
        force = try? container.decodeIfPresent(Force.self, forKey: .force)
        traffic = try? container.decodeIfPresent(Traffic.self, forKey: .traffic)
        sticky = try? container.decodeIfPresent(OverrideFeature.self, forKey: .sticky)
        initial = try? container.decodeIfPresent(OverrideFeature.self, forKey: .initial)
        variation = try? container.decodeIfPresent(Variation.self, forKey: .variation)
        variationValue = try? container.decodeIfPresent(
            VariationValue.self,
            forKey: .variationValue
        )
        variableKey = try? container.decodeIfPresent(VariableKey.self, forKey: .variableKey)
        variableValue = try? container.decodeIfPresent(VariableValue.self, forKey: .variableValue)
        variableSchema = try? container.decodeIfPresent(
            VariableSchema.self,
            forKey: .variableSchema
        )
    }

    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: Any] } ?? [:]
    }
}

let emptyDatafile = DatafileContent(
    schemaVersion: "1",
    revision: "unknown",
    attributes: [],
    segments: [],
    features: []
)

public class FeaturevisorInstance {
    // from options
    internal var datafileUrl: String?
    internal var handleDatafileFetch: DatafileFetchHandler?
    internal var refreshInterval: TimeInterval?  // seconds
    internal var bucketKeySeparator: String
    internal var configureBucketValue: ConfigureBucketValue?
    internal var configureBucketKey: ConfigureBucketKey?
    internal var initialFeatures: InitialFeatures?
    internal var interceptContext: InterceptContext?
    internal var logger: Logger
    internal var stickyFeatures: StickyFeatures?

    // internally created
    internal var timer: Timer?
    internal var datafileReader: DatafileReader
    internal var emitter: Emitter
    internal var statuses: Statuses
    internal var urlSession: URLSession

    // exposed from emitter
    public var on: ((EventName, @escaping Listener) -> Void)?
    public var addListener: ((EventName, @escaping Listener) -> Void)?
    public var off: ((EventName, Listener) -> Void)?
    public var removeListener: ((EventName, Listener) -> Void)?
    public var removeAllListeners: ((EventName?) -> Void)?

    internal init(options: InstanceOptions) throws {
        // from options
        bucketKeySeparator = options.bucketKeySeparator
        configureBucketKey = options.configureBucketKey
        configureBucketValue = options.configureBucketValue
        datafileUrl = options.datafileUrl
        handleDatafileFetch = options.handleDatafileFetch
        initialFeatures = options.initialFeatures
        interceptContext = options.interceptContext
        logger = options.logger ?? createLogger()
        refreshInterval = options.refreshInterval
        stickyFeatures = options.stickyFeatures

        // internal
        urlSession = URLSession(configuration: options.sessionConfiguration)
        emitter = Emitter()
        statuses = Statuses(ready: false, refreshInProgress: false)

        // register events
        if let onReady = options.onReady {
            emitter.addListener(.ready, onReady)
        }

        if let onRefresh = options.onRefresh {
            emitter.addListener(.refresh, onRefresh)
        }

        if let onUpdate = options.onUpdate {
            emitter.addListener(.update, onUpdate)
        }

        if let onActivation = options.onActivation {
            emitter.addListener(.activation, onActivation)
        }

        // expose emitter methods
        on = emitter.addListener
        addListener = emitter.addListener
        off = emitter.removeListener
        removeListener = emitter.removeListener
        removeAllListeners = emitter.removeAllListeners

        // datafile
        if let datafileUrl = options.datafileUrl {
            datafileReader = DatafileReader(datafileContent: options.datafile ?? emptyDatafile)

            try fetchDatafileContent(
                from: datafileUrl,
                handleDatafileFetch: handleDatafileFetch
            ) { [weak self] result in
                switch result {
                    case .success(let datafileContent):
                        self?.datafileReader = DatafileReader(datafileContent: datafileContent)

                        self?.statuses.ready = true
                        self?.emitter.emit(EventName.ready)

                        if self?.refreshInterval != nil {
                            self?.startRefreshing()
                        }
                    case .failure(let error):
                        self?.logger.error("failed to fetch datafile", ["error": error])
                }
            }
        }
        else if let datafile = options.datafile {
            datafileReader = DatafileReader(datafileContent: datafile)
            statuses.ready = true

            emitter.emit(EventName.ready)
        }
        else {
            throw FeaturevisorError.missingDatafileOptions
        }
    }

    func setDatafile(_ datafileJSON: String) {

        guard let data = datafileJSON.data(using: .utf8) else {
            logger.error("could not get datafile as data representation")
            return
        }

        do {
            let datafileContent = try JSONDecoder().decode(DatafileContent.self, from: data)
            datafileReader = DatafileReader(datafileContent: datafileContent)
        }
        catch {
            logger.error("could not parse datafile", ["error": error])
        }
    }

    func setDatafile(_ datafileContent: DatafileContent) {
        datafileReader = DatafileReader(datafileContent: datafileContent)
    }

    func setStickyFeatures(stickyFeatures: StickyFeatures?) {
        self.stickyFeatures = stickyFeatures
    }

    func getRevision() -> String {
        return datafileReader.getRevision()
    }
}

public func createInstance(options: InstanceOptions) throws -> FeaturevisorInstance {
    return try FeaturevisorInstance(options: options)
}
