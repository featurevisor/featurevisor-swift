import FeaturevisorTypes
import Foundation

public struct InstanceOptions {

    private static let defaultBucketKeySeparator = "."

    /// An instance of `InstanceOptions` with sane defaults. This is a singleton instance.
    public static let `default` = InstanceOptions()

    public var bucketKeySeparator: String = defaultBucketKeySeparator
    public var configureBucketKey: ConfigureBucketKey?
    public var configureBucketValue: ConfigureBucketValue?
    public var datafile: DatafileContent?
    public var datafileUrl: String?
    public var handleDatafileFetch: DatafileFetchHandler?
    public var initialFeatures: InitialFeatures?
    public var interceptContext: InterceptContext?
    public var logger: Logger?
    // TODO: Make listener more specific like https://github.com/fahad19/featurevisor/blob/main/packages/sdk/src/instance.ts#L32C13-L32C31
    public var onActivation: Listener?
    public var onReady: Listener?
    public var onRefresh: Listener?
    public var onUpdate: Listener?
    public var refreshInterval: TimeInterval?  // seconds
    public var stickyFeatures: StickyFeatures?
    public var sessionConfiguration: URLSessionConfiguration = .default

    /// Initializes a `InstanceOptions` with default values
    private init() {}
}
