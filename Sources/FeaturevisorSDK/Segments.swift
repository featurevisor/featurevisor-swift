import FeaturevisorTypes
import Foundation

public func segmentIsMatched(segment: Segment, context: Context) -> Bool {
    return allConditionsAreMatched(condition: segment.conditions, context: context)
}

public func allGroupSegmentsAreMatched(
    groupSegments: GroupSegment,
    context: Context,
    datafileReader: DatafileReader
) -> Bool {
    switch groupSegments {
        case let .plain(segmentKey):
            if segmentKey == "*" {
                return true
            }

            if let segment = datafileReader.getSegment(segmentKey) {
                return segmentIsMatched(segment: segment, context: context)
            }

            return false

        case let .multiple(groupSegments):
            return groupSegments.allSatisfy { groupSegment in
                allGroupSegmentsAreMatched(
                    groupSegments: groupSegment,
                    context: context,
                    datafileReader: datafileReader
                )
            }

        case let .and(andGroupSegment):
            return andGroupSegment.and.allSatisfy { groupSegment in
                allGroupSegmentsAreMatched(
                    groupSegments: groupSegment,
                    context: context,
                    datafileReader: datafileReader
                )
            }

        case let .or(orGroupSegment):
            return orGroupSegment.or.contains { groupSegment in
                allGroupSegmentsAreMatched(
                    groupSegments: groupSegment,
                    context: context,
                    datafileReader: datafileReader
                )
            }

        case let .not(notGroupSegment):
            return !notGroupSegment.not.allSatisfy { groupSegment in
                allGroupSegmentsAreMatched(
                    groupSegments: groupSegment,
                    context: context,
                    datafileReader: datafileReader
                )
            }
    }
}
