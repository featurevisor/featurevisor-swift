import FeaturevisorTypes
import Foundation

extension FeaturevisorInstance {

    // MARK: - Feature

    public func getFeature(byKey featureKey: String) -> Feature? {
        return datafileReader.getFeature(featureKey)
    }

    func findForceFromFeature(
        _ feature: Feature,
        context: Context,
        datafileReader: DatafileReader
    ) -> ForceResult {

        var force: Force?
        var forceIndex: Int?

        for (index, currentForce) in feature.force.enumerated() {
            if let condition = currentForce.conditions,
                allConditionsAreMatched(condition: condition, context: context)
            {

                force = currentForce
                forceIndex = index
                break
            }

            if let segments = currentForce.segments,
                allGroupSegmentsAreMatched(
                    groupSegments: segments,
                    context: context,
                    datafileReader: datafileReader
                )
            {
                force = currentForce
                forceIndex = index
                break
            }
        }

        return .init(force: force, forceIndex: forceIndex)
    }

    func getMatchedTraffic(
        traffic: [Traffic],
        context: Context,
        datafileReader: DatafileReader
    ) -> Traffic? {

        return traffic.first(where: { traffic in

            if !allGroupSegmentsAreMatched(
                groupSegments: traffic.segments,
                context: context,
                datafileReader: datafileReader
            ) {
                return false
            }

            return true
        })
    }

    func getMatchedAllocation(
        traffic: Traffic,
        bucketValue: Int
    ) -> Allocation? {

        return traffic.allocation.first(where: { allocation in
            let start = allocation.range.start
            let end = allocation.range.end

            return start <= bucketValue && end >= bucketValue
        })
    }

    typealias MatchedTrafficAndAllocation = (
        matchedTraffic: Traffic?, matchedAllocation: Allocation?
    )

    func getMatchedTrafficAndAllocation(
        traffic: [Traffic],
        context: Context,
        bucketValue: Int,
        datafileReader: DatafileReader,
        logger: Logger
    ) -> MatchedTrafficAndAllocation {

        guard
            let matchedTraffic = traffic.first(where: { traffic in
                return allGroupSegmentsAreMatched(
                    groupSegments: traffic.segments,
                    context: context,
                    datafileReader: datafileReader
                )
            })
        else {
            return (
                matchedTraffic: nil,
                matchedAllocation: nil
            )
        }

        let matchedAllocation = getMatchedAllocation(
            traffic: matchedTraffic,
            bucketValue: bucketValue
        )

        return (
            matchedTraffic: matchedTraffic,
            matchedAllocation: matchedAllocation
        )
    }
}
