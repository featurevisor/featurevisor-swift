import Foundation

let HASH_SEED: UInt32 = 1
let MAX_HASH_VALUE = UInt32.max // 2^32 - 1
let MAX_BUCKETED_NUMBER = 100000 // 100% * 1000 to include three decimal places in the same integer value

func getBucketedNumber(bucketKey: String) -> Int {
  var hasher = Hasher()
  hasher.combine(bucketKey)
  let hashValue = UInt32(abs(hasher.finalize())) // Absolute value to prevent negative numbers
  let ratio = Double(hashValue) / Double(MAX_HASH_VALUE)
  return Int(floor(ratio * Double(MAX_BUCKETED_NUMBER)))
}
