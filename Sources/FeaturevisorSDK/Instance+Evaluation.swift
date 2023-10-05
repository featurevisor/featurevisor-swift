import FeaturevisorTypes

extension FeaturevisorInstance {

    // MARK: - Feature enabled

    public func isEnabled(featureKey: FeatureKey, context: Context = [:]) -> Bool {
        let evaluation = evaluateFlag(featureKey: featureKey, context: context)
        return evaluation.enabled == true
    }

    // MARK: - Variation

    public func evaluateVariation(featureKey: FeatureKey, context: Context = [:]) -> Evaluation {
        let evaluation: Evaluation

        let flag = evaluateFlag(featureKey: featureKey, context: context)

        if flag.enabled == false {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .disabled
            )

            logger.debug("feature is disabled", evaluation.toDictionary())

            return evaluation
        }

        // sticky
        if let variationValue = stickyFeatures?[featureKey]?.variation {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .sticky,
                variationValue: variationValue
            )

            logger.debug("using sticky variation", evaluation.toDictionary())

            return evaluation
        }

        // initial
        if !statuses.ready, let variationValue = initialFeatures?[featureKey]?.variation {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .initial,
                variationValue: variationValue
            )

            logger.debug("using initial variation", evaluation.toDictionary())

            return evaluation
        }

        guard let feature = getFeature(byKey: featureKey) else {
            // not found
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .notFound
            )

            logger.warn("feature not found", evaluation.toDictionary())

            return evaluation
        }

        guard !feature.variations.isEmpty else {
            // no variations
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .noVariations
            )

            logger.warn("no variations", evaluation.toDictionary())
            return evaluation
        }

        let finalContext = interceptContext != nil ? interceptContext!(context) : context

        // forced
        if let force = findForceFromFeature(
            feature,
            context: context,
            datafileReader: datafileReader
        ) {
            let variation = feature.variations.first(where: { variation in
                return variation.value == force.variation
            })

            if let variation {
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .forced,
                    variation: variation
                )

                logger.debug("forced variation found", evaluation.toDictionary())

                return evaluation
            }
        }

        // bucketing
        let bucketValue = getBucketValue(feature: feature, context: finalContext)

        let matchedTrafficAndAllocation = getMatchedTrafficAndAllocation(
            traffic: feature.traffic,
            context: finalContext,
            bucketValue: bucketValue,
            datafileReader: datafileReader,
            logger: logger
        )

        if let matchedTraffic = matchedTrafficAndAllocation.matchedTraffic {

            // override from rule
            if let matchedTrafficVariationValue = matchedTraffic.variation {

                let variation = feature.variations.first(where: { variation in
                    return variation.value == matchedTrafficVariationValue
                })

                if let variation {
                    evaluation = Evaluation(
                        featureKey: feature.key,
                        reason: .rule,
                        bucketValue: bucketValue,
                        ruleKey: matchedTraffic.key,
                        variation: variation
                    )

                    logger.debug("override from rule", evaluation.toDictionary())

                    return evaluation
                }
            }

            // regular allocation
            if let matchedAllocation = matchedTrafficAndAllocation.matchedAllocation {

                let variation = feature.variations.first(where: { variation in
                    variation.value == matchedAllocation.variation
                })

                if let variation {
                    evaluation = Evaluation(
                        featureKey: feature.key,
                        reason: .allocated,
                        bucketValue: bucketValue,
                        variation: variation
                    )

                    logger.debug("allocated variation", evaluation.toDictionary())

                    return evaluation
                }
            }
        }

        // nothing matched
        evaluation = Evaluation(
            featureKey: feature.key,
            reason: .error,
            bucketValue: bucketValue
        )

        logger.debug("no matched variation", evaluation.toDictionary())

        return evaluation
    }

    // MARK: - Flag

    public func evaluateFlag(featureKey: FeatureKey, context: Context = [:]) -> Evaluation {
        let evaluation: Evaluation

        // sticky
        if let stickyFeature = stickyFeatures?[featureKey] {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .sticky,
                enabled: stickyFeature.enabled,
                sticky: stickyFeature
            )

            logger.debug("using sticky enabled", evaluation.toDictionary())

            return evaluation
        }

        // initial
        if statuses.ready, let initialFeature = initialFeatures?[featureKey] {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .initial,
                enabled: initialFeature.enabled,
                initial: initialFeature
            )

            logger.debug("using initial enabled", evaluation.toDictionary())

            return evaluation
        }

        let feature = getFeature(byKey: featureKey)

        // not found
        guard let feature else {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .notFound
            )

            logger.warn("feature not found", evaluation.toDictionary())

            return evaluation
        }

        // deprecated
        if feature.deprecated == true {
            logger.warn("feature is deprecated", ["featureKey": feature.key])
        }

        let finalContext = interceptContext != nil ? interceptContext!(context) : context

        // forced
        let force = findForceFromFeature(feature, context: context, datafileReader: datafileReader)

        if let force, force.enabled != nil {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .forced,
                enabled: force.enabled
            )

            logger.debug("forced enabled found", evaluation.toDictionary())

            return evaluation
        }

        // required
        if !feature.required.isEmpty {
            let requiredFeaturesAreEnabled = feature.required.allSatisfy({ item in
                let requiredKey: FeatureKey
                let requiredVariation: VariationValue?

                switch item {
                    case .featureKey(let featureKey):
                        requiredKey = featureKey
                        requiredVariation = nil
                    case .withVariation(let variation):
                        requiredKey = variation.key
                        requiredVariation = variation.variation
                }

                let requiredIsEnabled = isEnabled(featureKey: requiredKey, context: finalContext)

                if !requiredIsEnabled {
                    return false
                }

                if let requiredVariation,
                    let requiredVariationValue = getVariation(
                        featureKey: requiredKey,
                        context: finalContext
                    )
                {
                    return requiredVariationValue == requiredVariation
                }

                return true
            })

            if !requiredFeaturesAreEnabled {
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .required,
                    enabled: requiredFeaturesAreEnabled
                )

                return evaluation
            }
        }

        // bucketing
        let bucketValue = getBucketValue(feature: feature, context: finalContext)

        let matchedTraffic = getMatchedTraffic(
            traffic: feature.traffic,
            context: finalContext,
            datafileReader: datafileReader
        )

        if let matchedTraffic {

            if !feature.ranges.isEmpty {

                let matchedRange = feature.ranges.first(where: { range in
                    return bucketValue >= range.start && bucketValue < range.end
                })

                // matched
                if matchedRange != nil {
                    evaluation = Evaluation(
                        featureKey: feature.key,
                        reason: .allocated,
                        bucketValue: bucketValue,
                        enabled: matchedTraffic.enabled ?? true
                    )

                    return evaluation
                }

                // no match
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .outOfRange,
                    bucketValue: bucketValue,
                    enabled: false
                )

                logger.debug("not matched", evaluation.toDictionary())

                return evaluation
            }

            // override from rule
            if let matchedTrafficEnabled = matchedTraffic.enabled {
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .override,
                    bucketValue: bucketValue,
                    ruleKey: matchedTraffic.key,
                    enabled: matchedTrafficEnabled,
                    traffic: matchedTraffic
                )

                logger.debug("override from rule", evaluation.toDictionary())

                return evaluation
            }

            // treated as enabled because of matched traffic
            if bucketValue < matchedTraffic.percentage {
                // @TODO: verify if range check should be inclusive or not
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .rule,
                    bucketValue: bucketValue,
                    ruleKey: matchedTraffic.key,
                    enabled: true,
                    traffic: matchedTraffic
                )

                return evaluation
            }
        }

        // nothing matched
        evaluation = Evaluation(
            featureKey: feature.key,
            reason: .error,
            bucketValue: bucketValue,
            enabled: false
        )

        return evaluation
    }

    // MARK: - Variable

    public func evaluateVariable(
        featureKey: FeatureKey,
        variableKey: VariableKey,
        context: Context = [:]
    ) -> Evaluation {

        let evaluation: Evaluation

        let flag = evaluateFlag(featureKey: featureKey, context: context)

        if flag.enabled == false {
            evaluation = Evaluation(featureKey: featureKey, reason: .disabled)

            logger.debug("feature is disabled", evaluation.toDictionary())

            return evaluation
        }

        // sticky
        if let variableValue = stickyFeatures?[featureKey]?.variables?[variableKey] {
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .sticky,
                variableKey: variableKey,
                variableValue: variableValue
            )

            logger.debug("using sticky variable", evaluation.toDictionary())

            return evaluation
        }

        // initial
        if !statuses.ready, let initialFeature = initialFeatures?[featureKey] {

            if let variableValue = initialFeature.variables?[variableKey] {
                evaluation = Evaluation(
                    featureKey: featureKey,
                    reason: .initial,
                    variableKey: variableKey,
                    variableValue: variableValue
                )

                logger.debug("using initial variable", evaluation.toDictionary())

                return evaluation
            }
        }

        guard let feature = getFeature(byKey: featureKey) else {
            // not found
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .notFound,
                variableKey: variableKey
            )

            logger.warn("feature not found in datafile", evaluation.toDictionary())

            return evaluation
        }

        let variableSchema = feature.variablesSchema.first(where: { variableSchema in
            variableSchema.key == variableKey
        })

        guard let variableSchema else {
            // variable schema not found
            evaluation = Evaluation(
                featureKey: featureKey,
                reason: .notFound,
                variableKey: variableKey
            )

            logger.warn("variable schema not found", evaluation.toDictionary())

            return evaluation
        }

        let finalContext = interceptContext != nil ? interceptContext!(context) : context

        // forced
        let force = findForceFromFeature(feature, context: context, datafileReader: datafileReader)

        if let force, let variableValue = force.variables[variableKey] {
            evaluation = Evaluation(
                featureKey: feature.key,
                reason: .forced,
                variableKey: variableKey,
                variableValue: variableValue,
                variableSchema: variableSchema
            )

            logger.debug("forced variable", evaluation.toDictionary())

            return evaluation
        }

        // bucketing
        let bucketValue = getBucketValue(feature: feature, context: finalContext)

        let matchedTrafficAndAllocation = getMatchedTrafficAndAllocation(
            traffic: feature.traffic,
            context: finalContext,
            bucketValue: bucketValue,
            datafileReader: datafileReader,
            logger: logger
        )

        if let matchedTraffic = matchedTrafficAndAllocation.matchedTraffic {
            // override from rule
            if let variableValue = matchedTraffic.variables?[variableKey] {
                evaluation = Evaluation(
                    featureKey: feature.key,
                    reason: .rule,
                    bucketValue: bucketValue,
                    ruleKey: matchedTraffic.key,
                    variableKey: variableKey,
                    variableValue: variableValue,
                    variableSchema: variableSchema
                )

                logger.debug("override from rule", evaluation.toDictionary())

                return evaluation
            }

            // regular allocation
            if let matchedAllocation = matchedTrafficAndAllocation.matchedAllocation {

                let variation = feature.variations.first(where: { variation in
                    return variation.value == matchedAllocation.variation
                })

                if let variationVariables = variation?.variables {
                    let variableFromVariation = variationVariables.first(where: { variable in
                        return variable.key == variableKey
                    })

                    if let overrides = variableFromVariation?.overrides {
                        let override = overrides.first(where: { override in
                            if let condition = override.conditions {
                                return allConditionsAreMatched(
                                    condition: condition,
                                    context: finalContext
                                )
                            }

                            if let segments = override.segments {
                                return allGroupSegmentsAreMatched(
                                    groupSegments: segments,
                                    context: finalContext,
                                    datafileReader: datafileReader
                                )
                            }

                            return false
                        })

                        if let override {
                            evaluation = Evaluation(
                                featureKey: feature.key,
                                reason: .override,
                                bucketValue: bucketValue,
                                ruleKey: matchedTraffic.key,
                                variableKey: variableKey,
                                variableValue: override.value,
                                variableSchema: variableSchema
                            )

                            logger.debug("variable override", evaluation.toDictionary())

                            return evaluation
                        }
                    }

                    if let variableFromVariationValue = variableFromVariation?.value {
                        evaluation = Evaluation(
                            featureKey: feature.key,
                            reason: .allocated,
                            bucketValue: bucketValue,
                            ruleKey: matchedTraffic.key,
                            variableKey: variableKey,
                            variableValue: variableFromVariationValue,
                            variableSchema: variableSchema
                        )

                        logger.debug("allocated variable", evaluation.toDictionary())

                        return evaluation
                    }
                }
            }
        }

        // fall back to default
        evaluation = Evaluation(
            featureKey: feature.key,
            reason: .defaulted,
            bucketValue: bucketValue,
            variableKey: variableKey,
            variableValue: variableSchema.defaultValue,
            variableSchema: variableSchema
        )

        logger.debug("using default value", evaluation.toDictionary())

        return evaluation
    }
}

extension FeaturevisorInstance {

    // MARK: - Bucketing

    fileprivate func getFeature(byKey featureKey: String) -> Feature? {
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

        let result =
            bucketKey.map {
                $0.stringValue
            }
            .joined(separator: self.bucketKeySeparator)

        if let configureBucketKey = self.configureBucketKey {
            return configureBucketKey(feature, context, result)
        }

        return result
    }

    fileprivate func getBucketValue(feature: Feature, context: Context) -> BucketValue {

        let bucketKey = getBucketKey(feature: feature, context: context)
        let value = Bucket.resolveNumber(forKey: bucketKey)

        if let configureBucketValue = self.configureBucketValue {
            return configureBucketValue(feature, context, value)
        }

        return value
    }
}
