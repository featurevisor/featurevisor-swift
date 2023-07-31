import FeaturevisorTypes
import Foundation

public typealias ConfigureBucketKey = (Feature, Context, BucketKey) -> BucketKey
public typealias ConfigureBucketValue = (Feature, Context, BucketValue) -> BucketValue
public typealias InterceptContext = (Context) -> Context
// TODO: handle async here
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

func fetchDatafileContent(from url: String, completion: @escaping (Result<DatafileContent, Error>) -> Void) {
  let datafileUrl = URL(string: url)!
  let task = URLSession.shared.dataTask(with: datafileUrl) { (data, response, error) in
    if let error = error {
      completion(.failure(error))
    } else if let data = data {
      let decoder = JSONDecoder()
      // TODO: use real implementation instead of the mock one
      // Here we've got the non trivial problem that DatafileContnent is not decoadable
      // let content = try decoder.decode(DatafileContent.self, from: data)
      let mockAttributes: [Attribute] = [
        Attribute(key: "deviceId", type: "string", archived: false),
        Attribute(key: "userId", type: "string", archived: false)
      ]
      let content = DatafileContent(schemaVersion: "1", revision: "0.0.3", attributes: mockAttributes, segments: [], features: [])
      completion(.success(content))
    }
  }
  task.resume()
}



public struct InstanceOptions {
  public var bucketKeySeparator: String?
  public var configureBucketKey: ConfigureBucketKey?
  public var configureBucketValue: ConfigureBucketValue?
  public var datafile: DatafileContent?
  public var datafileUrl: String?
  //public var handleDatafileFetch: DatafileFetchHandler?
  public var initialFeatures: InitialFeatures?
  public var interceptContext: InterceptContext?
  public var logger: Logger?
  // TODO: Make listener more specific like https://github.com/fahad19/featurevisor/blob/main/packages/sdk/src/instance.ts#L32C13-L32C31
  public var onActivation: Listener?
  public var onReady: Listener?
  public var onRefresh: Listener?
  public var onUpdate: Listener?
  public var refreshInterval: Int?  // seconds
  public var stickyFeatures: StickyFeatures?

  // I hate the duplication here but I haven't found a better way.
  // We have to explicitely declare "public" the init if we want to use it
  // in another module.
  public init(
    bucketKeySeparator: String? = nil,
    configureBucketKey: ConfigureBucketKey? = nil,
    configureBucketValue: ConfigureBucketValue? = nil,
    datafile: DatafileContent? = nil,
    datafileUrl: String? = nil,
    // handleDatafileFetch: DatafileFetchHandler? = nil,
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
    // self.handleDatafileFetch = handleDatafileFetch
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

public enum FeaturevisorError: Error {
    case missingDatafileOptions
    case downloadingDatafile(String)
}

extension FeaturevisorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingDatafileOptions:
            return "Featurevisor SDK instance cannot be created without both `datafile` and `datafileUrl` options"
        case .downloadingDatafile(let datafileUrl):
            return "Featurevisor SDK was not able to download the data file at: \(datafileUrl)"
        }
    }
}

public class FeaturevisorInstance {
  static let DEFAULT_BUCKET_KEY_SEPARATOR = "."

  // from options
  private var bucketKeySeparator: String
  private var configureBucketKey: ConfigureBucketKey?
  private var configureBucketValue: ConfigureBucketValue?
  private var datafileUrl: String?
  //private var handleDatafileFetch: DatafileFetchHandler?
  private var initialFeatures: InitialFeatures?
  private var interceptContext: InterceptContext?
  private var logger: Logger
  private var refreshInterval: Int?  // seconds
  private var stickyFeatures: StickyFeatures?

  // internally created
  private var datafileReader: DatafileReader
  private var emitter: Emitter
  private var statuses: Statuses
  // private var intervalId: Timer?

  // exposed from emitter
  public var on: ((EventName, @escaping Listener) -> Void)?
  public var addListener: ((EventName, @escaping Listener) -> Void)?
  public var off: ((EventName, Listener) -> Void)?
  public var removeListener: ((EventName, Listener) -> Void)?
  public var removeAllListeners: ((EventName?) -> Void)?

  public init(options: InstanceOptions) throws {
    // from options
    bucketKeySeparator =
      options.bucketKeySeparator ?? FeaturevisorInstance.DEFAULT_BUCKET_KEY_SEPARATOR
    configureBucketKey = options.configureBucketKey
    configureBucketValue = options.configureBucketValue
    datafileUrl = options.datafileUrl
    //handleDatafileFetch = options.handleDatafileFetch
    initialFeatures = options.initialFeatures
    interceptContext = options.interceptContext
    logger = options.logger ?? createLogger()
    refreshInterval = options.refreshInterval
    stickyFeatures = options.stickyFeatures

    // internal
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

      // TODO: missing option `handleDatafileFetch`
      fetchDatafileContent(from: datafileUrl) { result in
        switch result {
        case .success(let datafileContent):
          self.datafileReader = DatafileReader(datafileContent: datafileContent)

          self.statuses.ready = true
          self.emitter.emit(EventName.ready)

          if self.refreshInterval != nil {
            self.startRefreshing()
          }
        case .failure(let error):
          self.logger.error("Failed to fetch datafile: \(error)")
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

  func setStickyFeatures(stickyFeatures: StickyFeatures?) {
      self.stickyFeatures = stickyFeatures
  }

  func getRevision() -> String {
    return self.datafileReader.getRevision();
  }

  // MARK: - Bucketing

  private func getFeature(featureKey: String) -> Feature? {
      return self.datafileReader.getFeature(featureKey)
  }

//    private func getBucketKey(feature: Feature, context: Context) -> BucketKey {
//        // TODO: write implementation
//        let featureKey = feature.key;
//
//        let type:BucketBy
//        let attributeKeys: [BucketBy]
//
//        switch feature.bucketBy {
//        case .single:
//            type = BucketBy.single(feature.key)
//            attributeKeys = [feature.bucketBy]
//        case .and:
//            type = BucketBy.and(feature.key)
//            attributeKeys = feature.bucketBy
//        case .or:
//            type = BucketBy.or(feature.key)
//        }
//    }

  // MARK: - Statuses

  func isReady() -> Bool {
    return self.statuses.ready
  }

  // MARK: - Refresh

  func refresh() -> Void {
      // TODO: write implementation
  }

  func startRefreshing() -> Void {
      // TODO: write implementation
  }

  func stopRefreshing() -> Void {
      // TODO: write implementation
  }

  // MARK: - Variation


  func evaluateVariation(feature: Feature, context: Context) -> Evaluation {
      return evaluateVariation(featureKey: feature.key, context: context)
  }
  func evaluateVariation(featureKey: FeatureKey, context: Context) -> Evaluation {
    //TODO: write real implementation
    return Evaluation(featureKey: "headerBanner", reason: EvaluationReason.allocated, bucketValue: nil, ruleKey: nil, error: nil, enabled: nil, traffic: nil, sticky: nil, initial: nil, variation: nil, variationValue: "twitter", variableKey: nil, variableValue: nil, variableSchema: nil)
  }

//  // TODO: write implementation
  public func getVariation(feature: Feature, context: Context) -> VariationValue? {
      return getVariation(featureKey: feature.key, context: context)
  }
  public func getVariation(featureKey: FeatureKey, context: Context) -> VariationValue? {
    let evaluation = self.evaluateVariation(featureKey: featureKey, context: context)

    if let variationValue = evaluation.variationValue {
        return variationValue
    }

    if let variation = evaluation.variation {
        return variation.value
    }

    return nil
  }

//  func getVariationBoolean(feature: Feature, context: Context) -> Bool? {
//      return getVariationBoolean(featureKey: feature.key, context: context)
//  }
//  func getVariationBoolean(featureKey: FeatureKey, context: Context) -> Bool? {
//      let variationValue = self.getVariation(featureKey: featureKey, context: context)
//
//      // TODO: complete implementation
//      // return getValueByType(variationValue, "boolean") as boolean | undefined;
//  }
//
//  func getVariationString(feature: Feature, context: Context) -> String? {
//      return getVariationString(featureKey: feature.key, context: context)
//  }
//  func getVariationString(featureKey: FeatureKey, context: Context) -> String? {
//      let variationValue = self.getVariation(featureKey: featureKey, context: context)
//
//      // TODO: complete implementation
//      // return getValueByType(variationValue, "string") as string | undefined;
//  }
//
//  func getVariationInteger(feature: Feature, context: Context) -> Int? {
//      return getVariationInteger(featureKey: feature.key, context: context)
//  }
//  func getVariationInteger(featureKey: FeatureKey, context: Context) -> Int? {
//      let variationValue = self.getVariation(featureKey: featureKey, context: context)
//
//      // TODO: complete implementation
//      // return getValueByType(variationValue, "integer") as number | undefined;
//  }
//
//  func getVariationDouble(feature: Feature, context: Context) -> Double? {
//      return getVariationDouble(featureKey: feature.key, context: context)
//  }
//  func getVariationDouble(featureKey: FeatureKey, context: Context) -> Double? {
//      let variationValue = self.getVariation(featureKey: featureKey, context: context)
//
//      // TODO: complete implementation
//      // return getValueByType(variationValue, "double") as number | undefined;
//  }

  // MARK: - Activate

//  func activate(featureKey: FeatureKey, context: Context) -> VariationValue? {
//      // TODO: complete implementation
//  }
//
//  func activateBoolean(featureKey: FeatureKey, context: Context) -> Bool? {
//      let variationValue = self.activate(featureKey: featureKey, context: context)
////      TODO: implement in Swift
////      return getValueByType(variationValue, "boolean") as boolean | undefined;
//  }
//
//  func activateString(featureKey: FeatureKey, context: Context) ->  String? {
//      let variationValue = self.activate(featureKey: featureKey, context: context)
//      //      TODO: implement in Swift
////        return getValueByType(variationValue, "string") as string | undefined;
//  }
//
//  func activateInteger(featureKey: FeatureKey, context: Context) -> Int? {
//      let variationValue = self.activate(featureKey: featureKey, context: context)
//
//      //      TODO: implement in Swift
//    //return getValueByType(variationValue, "integer") as number | undefined;
//  }
//
//  func activateDouble(featureKey: FeatureKey, context: Context) -> Double {
//      let variationValue = self.activate(featureKey: featureKey, context: context)
//      //      TODO: implement in Swift
//    // return getValueByType(variationValue, "double") as number | undefined;
//  }

  // MARK: - Variable
//  func evaluateVariable(
//    feature: Feature,
//    variableKey: VariableKey,
//    context: Context
//  ) ->  Evaluation {
//      return evaluateVariable(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func evaluateVariable(
//    featureKey: FeatureKey,
//    variableKey: VariableKey,
//    context: Context
//  ) ->  Evaluation {
//      // TODO: implement
//  }

//  func getVariable(
//      feature: Feature,
//      variableKey: String,
//      context: Context
//  ) ->  VariableValue? {
//      return getVariable(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariable(
//      featureKey: FeatureKey,
//      variableKey: String,
//      context: Context
//  ) ->  VariableValue? {
//      // TODO: implement
//  }

//  func getVariableBoolean(
//    feature: Feature,
//    variableKey: String,
//    context: Context
//  ) -> Bool? {
//      return getVariableBoolean(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariableBoolean(
//    featureKey: FeatureKey,
//    variableKey: String,
//    context: Context
//  ) -> Bool? {
//      let variableValue = self.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
//      // TODO: implement in Swift
//    //return getValueByType(variableValue, "boolean") as boolean | undefined;
//  }

//  func getVariableString(
//    feature: Feature,
//    variableKey: String,
//    context: Context
//  ) ->  String? {
//      return getVariableString(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariableString(
//    featureKey: FeatureKey,
//    variableKey: String,
//    context: Context
//  ) ->  String? {
//      let variableValue = self.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
//      // TODO: implement
////      return getValueByType(variableValue, "string") as string | undefined;
//  }

//  func getVariableInteger(
//    feature: Feature,
//    variableKey: String,
//    context: Context
//  ) ->  Int? {
//      return getVariableInteger(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariableInteger(
//    featureKey: FeatureKey,
//    variableKey: String,
//    context: Context
//  ) ->  Int? {
//      let variableValue = self.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
//      // TODO: implement
//    // return getValueByType(variableValue, "integer") as number | undefined;
//  }

//  func getVariableDouble(
//    feature: Feature,
//    variableKey: String,
//    context: Context
//  ) -> Double? {
//      return getVariableDouble(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariableDouble(
//    featureKey: FeatureKey,
//    variableKey: String,
//    context: Context
//  ) -> Double? {
//      let variableValue = self.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
//      // TODO: implement
//    // return getValueByType(variableValue, "double") as number | undefined;
//  }

//  func getVariableArray(
//    feature: Feature,
//    variableKey: String,
//    context: Context
//  ) -> [String]? {
//      return getVariableArray(featureKey: feature.key, variableKey: variableKey, context: context)
//  }
//  func getVariableArray(
//    featureKey: FeatureKey,
//    variableKey: String,
//    context: Context
//  ) -> [String]? {
//      let variableValue = self.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
//      // TODO: implement
//    // return getValueByType(variableValue, "array") as string[] | undefined;
//  }


  // TODO: implement in Swift
//    getVariableObject<T>(
//      featureKey: FeatureKey | Feature,
//      variableKey: string,
//      context: Context = {},
//    ): T | undefined {
//      const variableValue = this.getVariable(featureKey, variableKey, context);
//
//      return getValueByType(variableValue, "object") as T | undefined;
//    }

  // TODO: implement in Swift
//    getVariableJSON<T>(
//      featureKey: FeatureKey | Feature,
//      variableKey: string,
//      context: Context = {},
//    ): T | undefined {
//      const variableValue = this.getVariable(featureKey, variableKey, context);
//
//      return getValueByType(variableValue, "json") as T | undefined;
//    }
//  }
}

public func createInstance(options: InstanceOptions) -> FeaturevisorInstance? {
  do {
      let instance = try FeaturevisorInstance(options: options)
      return instance
    // TODO: What to do in case initialisation fails?
//  } catch FeaturevisorError.missingDatafileOptions{
//  } catch FeaturevisorError.downloadingDatafile(let datafileUrl) {
  } catch let error{
    print(error.localizedDescription)
  }

  return nil
}
