import FeaturevisorTypes

public extension FeaturevisorInstance {
    
    // MARK: - Variation

    func getVariation(featureKey: FeatureKey, context: Context) -> VariationValue? {
        let evaluation = evaluateVariation(featureKey: featureKey, context: context)

        if let variationValue = evaluation.variationValue {
            return variationValue
        }

        if let variation = evaluation.variation {
            return variation.value
        }

        return nil
    }

}
