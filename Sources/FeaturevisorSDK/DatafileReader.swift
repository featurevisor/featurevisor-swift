import FeaturevisorTypes

public class DatafileReader {
    let schemaVersion: String
    let revision: String
    let attributes: [AttributeKey: Attribute]
    let segments: [SegmentKey: Segment]
    let features: [FeatureKey: Feature]

    init(datafileContent: DatafileContent) {
        self.schemaVersion = datafileContent.schemaVersion
        self.revision = datafileContent.revision
        self.segments = Dictionary(
            uniqueKeysWithValues: datafileContent.segments.map { ($0.key, $0) }
        )
        self.attributes = Dictionary(
            uniqueKeysWithValues: datafileContent.attributes.map { ($0.key, $0) }
        )
        self.features = Dictionary(
            uniqueKeysWithValues: datafileContent.features.map { ($0.key, $0) }
        )
    }

    public func getRevision() -> String {
        return self.revision
    }

    public func getSchemaVersion() -> String {
        return self.schemaVersion
    }

    public func getAllAttributes() -> [Attribute] {
        return Array(attributes.values)
    }

    public func getAttribute(_ attributeKey: AttributeKey) -> Attribute? {
        return self.attributes[attributeKey]
    }

    public func getSegment(_ segmentKey: SegmentKey) -> Segment? {
        return segments[segmentKey]
    }

    public func getFeature(_ featureKey: FeatureKey) -> Feature? {
        return features[featureKey]
    }
}
