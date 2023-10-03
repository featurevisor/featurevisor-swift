import FeaturevisorTypes
import Foundation

public typealias ConfigureBucketKey = (Feature, Context, BucketKey) -> BucketKey
public typealias ConfigureBucketValue = (Feature, Context, BucketValue) -> BucketValue
public typealias InterceptContext = (Context) -> Context
public typealias DatafileFetchHandler = (_ datafileUrl: String) -> Result<DatafileContent, Error>

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

public struct Evaluation {
    // required
    public let featureKey: FeatureKey
    public let reason: EvaluationReason

    // common
    public let bucketValue: BucketValue?
    public let ruleKey: RuleKey?
    public let error: Error?
    public let enabled: Bool?
    public let traffic: Traffic?
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
            bucketValue: BucketValue? = nil,
            ruleKey: RuleKey? = nil,
            error: Error? = nil,
            enabled: Bool? = nil,
            traffic: Traffic? = nil,
            sticky: OverrideFeature? = nil,
            initial: OverrideFeature? = nil,
            variation: Variation? = nil,
            variationValue: VariationValue? = nil,
            variableKey: VariableKey? = nil,
            variableValue: VariableValue? = nil,
            variableSchema: VariableSchema? = nil) {
        self.featureKey = featureKey
        self.reason = reason
        self.bucketValue = bucketValue
        self.ruleKey = ruleKey
        self.error = error
        self.enabled = enabled
        self.traffic = traffic
        self.sticky = sticky
        self.initial = initial
        self.variation = variation
        self.variationValue = variationValue
        self.variableKey = variableKey
        self.variableValue = variableValue
        self.variableSchema = variableSchema
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

            try fetchDatafileContent(from: datafileUrl, handleDatafileFetch: handleDatafileFetch) { [weak self] result in
                switch result {
                    case .success(let datafileContent):
                        self?.datafileReader = DatafileReader(datafileContent: datafileContent)

                        self?.statuses.ready = true
                        self?.emitter.emit(EventName.ready)

                        if self?.refreshInterval != nil {
                            self?.startRefreshing()
                        }
                    case .failure(let error):
                        self?.logger.error("Failed to fetch datafile: \(error)")
                }
            }
        } else if let datafile = options.datafile {
            datafileReader = DatafileReader(datafileContent: datafile)
            statuses.ready = true

            emitter.emit(EventName.ready)
        } else {
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
        } catch {
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
