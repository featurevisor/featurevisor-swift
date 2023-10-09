import FeaturevisorTypes
import Foundation
import MurmurHash_Swift

internal enum Bucket {

    private static let hashSeed: UInt32 = 1
    private static let maxHashValue: Double = pow(2, 32)  // 2^32
    private static let maxSegmentNumber = 100000
    // 100% * 1000 to include three decimal places in the same integer value

    static func resolveNumber(forKey bucketKey: BucketKey) -> Int {

        let hashValue = MurmurHash3.x86_32.digest(bucketKey, seed: hashSeed)
        let ratio = Double(hashValue) / maxHashValue

        return Int(floor(ratio * Double(maxSegmentNumber)))
    }
}
