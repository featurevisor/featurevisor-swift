import FeaturevisorTypes

public extension FeaturevisorInstance {

    // MARK: - Activate

    func activate(featureKey: FeatureKey, context: Context = [:]) -> VariationValue? {
        do {
            let evaluation = evaluateVariation(featureKey: featureKey, context: context)
            let variationValue = evaluation.variation?.value ?? evaluation.variationValue

            guard let variationValue else {
                return nil
            }

            let finalContext = interceptContext != nil ? interceptContext!(context) : context

            var captureContext: Context = [:]

            let attributesForCapturing = datafileReader.getAllAttributes().filter { $0.capture == true }

            attributesForCapturing.forEach({ attribute in
                if finalContext[attribute.key] != nil {
                    captureContext[attribute.key] = context[attribute.key]
                }
            })

            emitter.emit(EventName.activation, featureKey, variationValue, finalContext, captureContext, evaluation)

            return variationValue
        } catch {
            logger.error("activate", ["featureKey": featureKey, "error": error])
            return nil
        }
    }
}