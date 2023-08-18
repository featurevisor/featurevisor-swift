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

let emptyDatafile = DatafileContent(
    schemaVersion: "1",
    revision: "unknown",
    attributes: [],
    segments: [],
    features: []
)

public class FeaturevisorInstance {
    
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
    internal var urlSession: URLSession
    // private var intervalId: Timer?

    // exposed from emitter
    public var on: ((EventName, @escaping Listener) -> Void)?
    public var addListener: ((EventName, @escaping Listener) -> Void)?
    public var off: ((EventName, Listener) -> Void)?
    public var removeListener: ((EventName, Listener) -> Void)?
    public var removeAllListeners: ((EventName?) -> Void)?

    public init(options: InstanceOptions) throws {
        // from options
        bucketKeySeparator = options.bucketKeySeparator
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

            // TODO: missing option `handleDatafileFetch`
            try fetchDatafileContent(from: datafileUrl) { [weak self] result in
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

    func setStickyFeatures(stickyFeatures: StickyFeatures?) {
        self.stickyFeatures = stickyFeatures
    }

    func getRevision() -> String {
        return self.datafileReader.getRevision()
    }

    // MARK: - Bucketing

    private func getFeature(featureKey: String) -> Feature? {
        return self.datafileReader.getFeature(featureKey)
    }

    private func getBucketKey(feature: Feature, context: Context) -> BucketKey {
        let featureKey = feature.key

        var type: String
        var attributeKeys: [AttributeKey]

        switch feature.bucketBy {
            case .single(let bucketBy):
                type = "plain"
                attributeKeys = [bucketBy]
            case .and(let bucketBy):
                type = "and"
                attributeKeys = bucketBy
            case .or(let bucketBy):
                type = "or"
                attributeKeys = bucketBy.or
        }

        var bucketKey: [AttributeValue] = []

        attributeKeys.forEach { attributeKey in
            guard let attributeValue = context[attributeKey] else {
                return
            }

            if type == "plain" || type == "and" {
                bucketKey.append(attributeValue)
            }
            else {  // or
                if bucketKey.isEmpty {
                    bucketKey.append(attributeValue)
                }
            }
        }

        bucketKey.append(.string(featureKey))

        let result = bucketKey.map { $0.stringValue }.joined(separator: self.bucketKeySeparator)

        if let configureBucketKey = self.configureBucketKey {
            return configureBucketKey(feature, context, result)
        }

        return result
    }

    private func getBucketValue(feature: Feature, context: Context) -> BucketValue {
        let bucketKey = getBucketKey(feature: feature, context: context)
        let value = Bucket.resolveNumber(forKey: bucketKey)

        if let configureBucketValue = self.configureBucketValue {
            return configureBucketValue(feature, context, value)
        }

        return value
    }

    // MARK: - Statuses

    func isReady() -> Bool {
        return self.statuses.ready
    }

    // MARK: - Refresh

    func refresh() {
        // TODO: write implementation
    }

    func startRefreshing() {
        // TODO: write implementation
    }

    func stopRefreshing() {
        // TODO: write implementation
    }

    // MARK: - Flag
    func evaluateFlag(feature: Feature, context: Context = [:]) -> Evaluation {
        return evaluateFlag(featureKey: feature.key, context: context)
    }
    func evaluateFlag(featureKey: FeatureKey, context: Context = [:]) -> Evaluation {
        //TODO: write real implementation
        return Evaluation(
            featureKey: featureKey,
            reason: EvaluationReason.allocated,
            bucketValue: nil,
            ruleKey: nil,
            error: nil,
            enabled: nil,
            traffic: nil,
            sticky: nil,
            initial: nil,
            variation: nil,
            variationValue: "twitter",
            variableKey: nil,
            variableValue: nil,
            variableSchema: nil
        )
    }

    public func isEnabled(featureKey: FeatureKey, context: Context = [:]) -> Bool {
        do {
            let evaluation = try evaluateFlag(featureKey: featureKey, context: context)
            return evaluation.enabled == true
        }
        catch {
            self.logger.error("isEnabled", ["featureKey": featureKey, "error": error])
            return false
        }
    }

    func evaluateVariation(feature: Feature, context: Context = [:]) -> Evaluation {
        return evaluateVariation(featureKey: feature.key, context: context)
    }
    func evaluateVariation(featureKey: FeatureKey, context: Context = [:]) -> Evaluation {
        // TODO: write real implementation
        return Evaluation(
            featureKey: "headerBanner",
            reason: EvaluationReason.allocated,
            bucketValue: nil,
            ruleKey: nil,
            error: nil,
            enabled: nil,
            traffic: nil,
            sticky: nil,
            initial: nil,
            variation: nil,
            variationValue: "twitter",
            variableKey: nil,
            variableValue: nil,
            variableSchema: nil
        )
    }

    public func getVariation(feature: Feature, context: Context = [:]) -> VariationValue? {
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

    // MARK: - Activate

    func activate(featureKey: FeatureKey, context: Context = [:]) -> VariationValue? {
        do {
            let evaluation = evaluateVariation(featureKey: featureKey, context: context)
            let variationValue = evaluation.variation?.value ?? evaluation.variationValue

            if variationValue == nil {
                return nil
            }

            let finalContext = interceptContext != nil ? interceptContext!(context) : context

            var captureContext: Context = [:]

            let attributesForCapturing = datafileReader.getAllAttributes().filter { $0.capture == true }

            for attribute in attributesForCapturing {
                if finalContext[attribute.key] != nil {
                    captureContext[attribute.key] = context[attribute.key]
                }
            }

            emitter.emit(EventName.activation, featureKey, variationValue!, finalContext, captureContext, evaluation)

            return variationValue
        } catch {
            logger.error("activate", ["featureKey": featureKey, "error": error])
            return nil
        }
    }

    // MARK: - Variable

      func evaluateVariable(
        feature: Feature,
        variableKey: VariableKey,
        context: Context
      ) ->  Evaluation {
          return evaluateVariable(featureKey: feature.key, variableKey: variableKey, context: context)
      }
      func evaluateVariable(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context = [:]
      ) ->  Evaluation {
          //TODO: write real implementation
          return Evaluation(
              featureKey: featureKey,
              reason: EvaluationReason.allocated,
              bucketValue: nil,
              ruleKey: nil,
              error: nil,
              enabled: nil,
              traffic: nil,
              sticky: nil,
              initial: nil,
              variation: nil,
              variationValue: "twitter",
              variableKey: variableKey,
              variableValue: nil,
              variableSchema: nil
          )
      }

      func getVariable(
          feature: Feature,
          variableKey: VariableKey,
          context: Context = [:]
      ) ->  VariableValue? {
          return getVariable(featureKey: feature.key, variableKey: variableKey, context: context)
      }
    
      func getVariable(
          featureKey: FeatureKey,
          variableKey: VariableKey,
          context: Context = [:]
      ) ->  VariableValue? {
          do {
              let evaluation = self.evaluateVariable(featureKey: featureKey, variableKey: variableKey, context: context)

              // TODO: missing part here
              return nil
          } catch {
              self.logger.error("getVariable", ["featureKey": featureKey, "variableKey": variableKey, "error": error])
              return nil
          }
      }

      func getVariableBoolean(
        feature: Feature,
        variableKey: VariableKey,
        context: Context) -> Bool? {
            return getVariableBoolean(featureKey: feature.key, variableKey: variableKey, context: context)
      }
    
      func getVariableBoolean(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context) -> Bool? {
            return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Bool
      }

      func getVariableString(
        feature: Feature,
        variableKey: VariableKey,
        context: Context) ->  String? {
          return getVariableString(featureKey: feature.key, variableKey: variableKey, context: context)
      }
    
      func getVariableString(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context) ->  String? {
          return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? String
      }

      func getVariableInteger(
        feature: Feature,
        variableKey: VariableKey,
        context: Context) ->  Int? {
          return getVariableInteger(featureKey: feature.key, variableKey: variableKey, context: context)
      }
    
      func getVariableInteger(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context) ->  Int? {
          return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Int
      }

      func getVariableDouble(
        feature: Feature,
        variableKey: VariableKey,
        context: Context) -> Double? {
          return getVariableDouble(featureKey: feature.key, variableKey: variableKey, context: context)
      }
    
      func getVariableDouble(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context) -> Double? {
          return getVariable(featureKey: featureKey, variableKey: variableKey, context: context)?.value as? Double
      }

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
