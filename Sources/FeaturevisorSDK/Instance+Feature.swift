import Foundation
import FeaturevisorTypes

extension FeaturevisorInstance {

    func findForceFromFeature(
            _ feature: Feature,
            context: Context,
            datafileReader: DatafileReader) -> Force? {

        return feature.force.first(where: { force in
            if let conditions = force.conditions {
                return allConditionsAreMatched(condition: conditions, context: context)
            }

            if let segments = force.segments {
                return allGroupSegmentsAreMatched(groupSegments: segments, context: context, datafileReader: datafileReader)
            }

            return false
        })
    }

    func getMatchedTraffic(
            traffic: [Traffic],
            context: Context,
            datafileReader: DatafileReader) -> Traffic? {

        return traffic.first(where: { traffic in

            if (!allGroupSegmentsAreMatched(groupSegments: traffic.segments, context: context, datafileReader: datafileReader)) {
                return false;
            }

            return true;
        });
    }
}


