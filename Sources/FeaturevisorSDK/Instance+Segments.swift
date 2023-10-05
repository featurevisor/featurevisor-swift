import FeaturevisorTypes
import Foundation

extension FeaturevisorInstance {

    // MARK: - Segments

    public func segmentIsMatched(featureKey: FeatureKey, context: Context) -> VariationValue? {
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

extension FeaturevisorInstance {

    func segmentIsMatched(segment: Segment, context: Context) -> Bool {
        return allConditionsAreMatched(condition: segment.conditions, context: context)
    }

    func allGroupSegmentsAreMatched(
        groupSegments: GroupSegment,
        context: Context,
        datafileReader: DatafileReader
    ) -> Bool {

        switch groupSegments {
            case .plain(let segmentKey):
                if segmentKey == "*" {
                    return true
                }

                if let segment = datafileReader.getSegment(segmentKey) {
                    return segmentIsMatched(segment: segment, context: context)
                }

                return false

            case .multiple(let groupSegments):
                return groupSegments.allSatisfy { groupSegment in
                    allGroupSegmentsAreMatched(
                        groupSegments: groupSegment,
                        context: context,
                        datafileReader: datafileReader
                    )
                }

            case .and(let andGroupSegment):
                return andGroupSegment.and.allSatisfy { groupSegment in
                    allGroupSegmentsAreMatched(
                        groupSegments: groupSegment,
                        context: context,
                        datafileReader: datafileReader
                    )
                }

            case .or(let orGroupSegment):
                return orGroupSegment.or.contains { groupSegment in
                    allGroupSegmentsAreMatched(
                        groupSegments: groupSegment,
                        context: context,
                        datafileReader: datafileReader
                    )
                }

            case .not(let notGroupSegment):
                return !notGroupSegment.not.allSatisfy { groupSegment in
                    allGroupSegmentsAreMatched(
                        groupSegments: groupSegment,
                        context: context,
                        datafileReader: datafileReader
                    )
                }
        }

    }
}
