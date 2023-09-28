import FeaturevisorTypes

public class DatafileReader {
    let schemaVersion: String
    let revision: String
    let attributes: [Attribute]
    let segments: [Segment]
    let features: [Feature]

    init(datafileContent: DatafileContent) {
        self.schemaVersion = datafileContent.schemaVersion
        self.revision = datafileContent.revision
        self.segments = datafileContent.segments
        self.attributes = datafileContent.attributes
        self.features = datafileContent.features
    }

    public func getRevision() -> String {
        return self.revision
    }

    public func getSchemaVersion() -> String {
        return self.schemaVersion
    }

    public func getAllAttributes() -> [Attribute] {
        return self.attributes
    }

    public func getAttribute(_ attributeKey: AttributeKey) -> Attribute? {
        return self.attributes.first(where: { $0.key == attributeKey })
    }

    public func getSegment(_ segmentKey: SegmentKey) -> Segment? {
        return segments.first(where: { $0.key == segmentKey })
    }

    public func getFeature(_ featureKey: FeatureKey) -> Feature? {
        return features.first(where: { $0.key == featureKey })
    }
}
