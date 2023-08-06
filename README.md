# featurevisor-swift

This repository is a work in progress to port the [Featurevisor](https://featurevisor.com) JavaScript SDK to Swift.

We are not ready yet. Please come back later.

## Installation

With [SPM](https://www.swift.org/package-manager/), add the package under `dependencies` in `Package.swift` file:

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
  name: "ExampleApp",
  dependencies: [
    // add the repo with desired semver as a dependency here
    .package(url: "git@github.com:featurevisor/featurevisor-swift.git", .exact("X.Y.Z"))
  ],
  .target(
    name: "ExampleApp",
    dependencies: [
      // add the name of module from the dependency in your desired targets
      "FeaturevisorSDK"
    ]
  )
)
```

Building your application will fetch and install everything locally:

```
$ swift build
```

## Usage

@TODO: ...

## Development

We wish to reach feature parity with the existing JavaScript SDK: https://featurevisor.com/docs/sdks/

We are breaking down the various parts that we need to migrate to Swift in the sections below:

### SDK API

(Table below requires review to get accurate status)

| Section             | Task                                                | Status |
|---------------------|-----------------------------------------------------|--------|
| Files               | `@featurevisor/types` ➡️ `FeaturevisorTypes`        | ✅      |
|                     | SDK's `bucket.ts` ➡️ `bucket.swift`                 | ✅      |
|                     | SDK's `conditions.ts` ➡️ `conditions.swift`         | ✅      |
|                     | SDK's `datafileReader.ts` ➡️ `DatafileReader.swift` | ✅      |
|                     | SDK's `emitter.ts` ➡️ `Emitter.swift`               | ✅      |
|                     | SDK's `feature.ts` ➡️ `Emitter.swift`               |        |
|                     | SDK's `instance.ts` ➡️ `Instance.swift`             |        |
|                     | SDK's `logger.ts` ➡️ `Logger.swift`                 | ✅      |
|                     | SDK's `segments.ts` ➡️ `segments.swift`             | ✅      |
|                     |                                                     |        |
| Constructor options | `bucketKeySeparator`                                | ✅     |
|                     | `configureBucketKey`                                | ✅     |
|                     | `configureBucketValue`                              | ✅     |
|                     | `datafile`                                          | ✅     |
|                     | `datafileUrl`                                       | ✅     |
|                     | `handleDatafileFetch`                               |        |
|                     | `initialFeatures`                                   | ✅     |
|                     | `interceptContext`                                  | ✅     |
|                     | `logger`                                            | ✅     |
|                     | `onActivation`                                      |        |
|                     | `onReady`                                           | ✅     |
|                     | `onRefresh`                                         | ✅     |
|                     | `onUpdate`                                          | ✅     |
|                     | `refreshInternal`                                   | ✅     |
|                     | `stickyFeatures`                                    | ✅     |
|                     |                                                     |        |
| Instance methods    | `constructor` missing fetch datafile content        | ⚠️      |
|                     | `setDatafile` removed to workaround init issues     | ✅     |
|                     | `setStickyFeatures`                                 | ✅     |
|                     | `getRevision`                                       | ✅     |
|                     | `getFeature`                                        | ✅     |
|                     | `getBucketKey`                                      | ✅     |
|                     | `getBucketValue`                                    | ✅     |
|                     | `isReady`                                           | ✅     |
|                     | `refresh`                                           |        |
|                     | `startRefreshing`                                   |        |
|                     | `stopRefreshing`                                    |        |
|                     | `evaluateFlag`                                      |        |
|                     | `isEnabled`                                         | ✅     |
|                     | `evaluateVariation`                                 |        |
|                     | `getVariation`                                      | ✅     |
|                     | `activate`                                          | ✅     |
|                     | `evaluateVariable`                                  |        |
|                     | `getVariable`                                       |        |
|                     | `getVariableBoolean`                                |        |
|                     | `getVariableString`                                 |        |
|                     | `getVariableInteger`                                |        |
|                     | `getVariableDouble`                                 |        |
|                     | `getVariableArray`                                  |        |
|                     | `getVariableObject`                                 |        |
|                     | `getVariableJSON`                                   |        |
|                     |                                                     |        |
| Functions           | `createInstance` missing proper error handling      | ⚠️      |
|                     | `fetchDatafileContent` decoadable issue             | ⚠️      |
|                     | `getValueByType`                                    |        |

### Test runner

We should also have an executable as an output of this repository that can be used to run the test specs against the Swift SDK: https://featurevisor.com/docs/testing/

Example command:

```
$ cd path/to/featurevisor-project-with-yamls
$ featurevisor-swift test
```

## License

MIT © [Fahad Heylaal](https://fahad19.com)
