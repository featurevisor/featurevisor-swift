import FeaturevisorTypes
import Foundation
import MurmurHash_Swift

internal enum Bucket {

    private static let HASH_SEED: UInt32 = 1
    private static let MAX_HASH_VALUE: Double = pow(2, 32)  // 2^32
    private static let MAX_BUCKETED_NUMBER = 100000  // 100% * 1000 to include three decimal places in the same integer value

    static func resolveNumber(forKey bucketKey: BucketKey) -> Int {

        let hashValue = MurmurHash3.x86_32.digest(bucketKey, seed: HASH_SEED)
        let ratio = Double(hashValue) / MAX_HASH_VALUE

        return Int(floor(ratio * Double(MAX_BUCKETED_NUMBER)))
    }
}
