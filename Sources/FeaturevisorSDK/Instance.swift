import FeaturevisorTypes
import Foundation

public typealias ConfigureBucketKey = (Feature, Context, BucketKey) -> BucketKey
public typealias ConfigureBucketValue = (Feature, Context, BucketValue) -> BucketValue
public typealias InterceptContext = (Context) -> Context
// @TODO: handle async here
public typealias DatafileFetchHandler = (String) -> DatafileContent

public struct Statuses {
  public var ready: Bool
  public var refreshInProgress: Bool
}

public enum EvaluationReason: String {
  case notFound = "not_found"
  case noVariations = "no_variations"
  case disabled
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
}

public struct InstanceOptions {
  public var bucketKeySeparator: String?
  public var configureBucketKey: ConfigureBucketKey?
  public var configureBucketValue: ConfigureBucketValue?
  public var datafile: DatafileContent?
  public var datafileUrl: String?
  public var handleDatafileFetch: DatafileFetchHandler?
  public var initialFeatures: InitialFeatures?
  public var interceptContext: InterceptContext?
  public var logger: Logger?
  // @TODO: Make listener more specific like https://github.com/fahad19/featurevisor/blob/main/packages/sdk/src/instance.ts#L32C13-L32C31
  public var onActivation: Listener?
  public var onReady: Listener?
  public var onRefresh: Listener?
  public var onUpdate: Listener?
  public var refreshInterval: Int?  // seconds
  public var stickyFeatures: StickyFeatures?

  public init(
    bucketKeySeparator: String? = nil,
    configureBucketKey: ConfigureBucketKey? = nil,
    configureBucketValue: ConfigureBucketValue? = nil,
    datafile: DatafileContent? = nil,
    datafileUrl: String? = nil,
    handleDatafileFetch: DatafileFetchHandler? = nil,
    initialFeatures: InitialFeatures? = nil,
    interceptContext: InterceptContext? = nil,
    logger: Logger? = nil,
    onActivation: Listener? = nil,
    onReady: Listener? = nil,
    onRefresh: Listener? = nil,
    onUpdate: Listener? = nil,
    refreshInterval: Int? = nil,
    stickyFeatures: StickyFeatures? = nil
  ) {
    self.bucketKeySeparator = bucketKeySeparator
    self.configureBucketKey = configureBucketKey
    self.configureBucketValue = configureBucketValue
    self.datafile = datafile
    self.datafileUrl = datafileUrl
    self.handleDatafileFetch = handleDatafileFetch
    self.initialFeatures = initialFeatures
    self.interceptContext = interceptContext
    self.logger = logger
    self.onActivation = onActivation
    self.onReady = onReady
    self.onRefresh = onRefresh
    self.onUpdate = onUpdate
    self.refreshInterval = refreshInterval
    self.stickyFeatures = stickyFeatures
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
  static let DEFAULT_BUCKET_KEY_SEPARATOR = "."

  // from options
  private var bucketKeySeparator: String
  private var configureBucketKey: ConfigureBucketKey?
  private var configureBucketValue: ConfigureBucketValue?
  private var datafileUrl: String?
  private var handleDatafileFetch: DatafileFetchHandler?
  private var initialFeatures: InitialFeatures?
  private var interceptContext: InterceptContext?
  private var logger: Logger
  private var refreshInterval: Int?  // seconds
  private var stickyFeatures: StickyFeatures?

  // internally created
  // private var datafileReader: DatafileReader
  private var emitter: Emitter
  private var statuses: Statuses
  // private var intervalId: Timer?

  // exposed from emitter
  public var on: ((EventName, @escaping Listener) -> Void)?
  public var addListener: ((EventName, @escaping Listener) -> Void)?
  public var off: ((EventName, Listener) -> Void)?
  public var removeListener: ((EventName, Listener) -> Void)?
  public var removeAllListeners: ((EventName?) -> Void)?

  public init(options: InstanceOptions) {
    // from options
    bucketKeySeparator =
      options.bucketKeySeparator ?? FeaturevisorInstance.DEFAULT_BUCKET_KEY_SEPARATOR
    configureBucketKey = options.configureBucketKey
    configureBucketValue = options.configureBucketValue
    datafileUrl = options.datafileUrl
    handleDatafileFetch = options.handleDatafileFetch
    initialFeatures = options.initialFeatures
    interceptContext = options.interceptContext
    logger = options.logger ?? createLogger()
    refreshInterval = options.refreshInterval
    stickyFeatures = options.stickyFeatures

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

    on = emitter.addListener
    addListener = emitter.addListener
    off = emitter.removeListener
    removeListener = emitter.removeListener
    removeAllListeners = emitter.removeAllListeners

    // datafile
    if let datafileUrl = options.datafileUrl {
      setDatafile(datafile: options.datafile ?? emptyDatafile)

      // @TODO: implement this
      //            fetchDatafileContent(options.datafileUrl, options.handleDatafileFetch)
      //                    .then((datafile) => {
      //                      this.setDatafile(datafile);
      //
      //                      this.statuses.ready = true;
      //                      this.emitter.emit("ready");
      //
      //                      if (this.refreshInterval) {
      //                        this.startRefreshing();
      //                      }
      //                    })
      //                    .catch((e) => {
      //                      this.logger.error("failed to fetch datafile", { error: e });
      //                    });
    }
    else if let datafile = options.datafile {
      setDatafile(datafile: datafile)
      statuses.ready = true

      emitter.emit(EventName.ready)
    }
    else {
      // @TODO: throw error
      //            throw new Error(
      //                "Featurevisor SDK instance cannot be created without both `datafile` and `datafileUrl` options",
      //            );
    }
  }

  private func setDatafile(datafile _: DatafileContent) {
    // @TODO: implement this
    //        try {
    //              this.datafileReader = new DatafileReader(
    //                typeof datafile === "string" ? JSON.parse(datafile) : datafile,
    //              );
    //            } catch (e) {
    //              this.logger.error("could not parse datafile", { error: e });
    //            }
  }

  /**
     * Flag
     */
  private func evaluateFlag(featureKey: FeatureKey, context _: Context) -> Evaluation {
    // @TODO: swap line below with real implementation (which is not trivial)
    Evaluation(
      featureKey: featureKey,
      reason: .allocated,
      bucketValue: nil,
      ruleKey: nil,
      error: nil,
      enabled: true,
      traffic: nil,
      sticky: nil,
      initial: nil,
      variation: nil,
      variationValue: nil,
      variableKey: nil,
      variableValue: nil,
      variableSchema: nil
    )
  }

  public func isEnabled(featureKey: FeatureKey, context: Context) -> Bool {
    do {
      let evaluation = evaluateFlag(featureKey: featureKey, context: context)

      return evaluation.enabled == true
    }
    catch {
      logger.error("isEnabled", ["featureKey": featureKey])
      return false
    }
  }
}

public func createInstance(options: InstanceOptions) -> FeaturevisorInstance {
  FeaturevisorInstance(options: options)
}
