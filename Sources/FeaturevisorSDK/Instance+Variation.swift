import FeaturevisorTypes

extension FeaturevisorInstance {

    // MARK: - Variation

    public func getVariation(featureKey: FeatureKey, context: Context) -> VariationValue? {
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
