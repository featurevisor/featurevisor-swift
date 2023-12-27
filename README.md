[![Featurevisor](./assets/banner-bordered.png)](https://featurevisor.com)

<div align="center">
  <h3><strong>Feature management for developers</strong></h3>
</div>

<div align="center">
  <small>Manage your feature flags and experiments declaratively from the comfort of your Git workflow.</small>
</div>

<br />

<div align="center">
  <!-- License -->
  <a href="./LICENSE">
    <img src="https://img.shields.io/npm/l/@featurevisor/sdk.svg?style=flat-square"
      alt="License" />
  </a>
</div>

<div align="center">
  <h3>
    <a href="https://featurevisor.com">
      Website
    </a>
    <span> | </span>
    <a href="https://featurevisor.com/docs">
      Documentation
    </a>
    <span> | </span>
    <a href="https://github.com/featurevisor/featurevisor-swift/issues">
      Issues
    </a>
    <span> | </span>
    <a href="https://featurevisor.com/docs/contributing">
      Contributing
    </a>
    <span> | </span>
  </h3>
</div>

---

# featurevisor-swift

This repository is a port of the [Featurevisor](https://featurevisor.com) JavaScript SDK to Swift.

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding Featurevisor as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/featurevisor/featurevisor-swift.git", .upToNextMajor(from: "X.Y.Z"))
]
```

## Usage

### Setting up Featurevisor SDK
We would like to be able to set up the Featurevisor SDK instance once and reuse the same instance everywhere.

The SDK can be initialized in two different ways depending on your needs.

### Synchronous
You can fetch the data file content on your own and just pass it via options.

```swift
import FeaturevisorSDK

let datafileContent: DatafileContent = ...
var options: InstanceOptions = .default
options.datafile = datafileContent

let featurevisor = try createInstance(options: options)
```

### Asynchronous
If you want to delegate the responsibility of fetching the datafile to the SDK.

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json" 
let featurevisor = try createInstance(options: options)
```

If you need to take further control on how the datafile is fetched, you can pass a custom `handleDatafileFetch` function

```swift
public typealias DatafileFetchHandler = (_ datafileUrl: String) -> Result<DatafileContent, Error>
```

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.handleDatafileFetch = { datafileUrl in
    ...
}
let featurevisor = try createInstance(options: options)
```

### Context
Contexts are a set of attribute values that we pass to SDK for evaluating features.

They are objects where keys are the attribute keys, and values are the attribute values.

```swift
public enum AttributeValue {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case date(Date)
```

```swift
let context = [
  "myAttributeKey": .string("myStringAttributeValue"),
  "anotherAttributeKey": .double(0.999),
]
```

### Checking if enabled
Once the SDK is initialized, you can check if a feature is enabled or not:

```swift
let featureKey = "my_feature";
let context = [
    "userId": .string("123"),
    "country": .string("nl")
]

let isEnabled = sdk.isEnabled(featureKey: featureKey, context: context)
```

### Getting variations
If your feature has any variations defined, you can get evaluate them as follows

```swift
let featureKey = "my_feature";
let context = [
    "userId": .string("123")
]

let variation = sdk.getVariation(featureKey: featureKey, context: context)
```

### Getting variables
```swift
let featureKey = "my_feature";
let variableKey = "color"
let context = [
    "userId": .string("123")
]
sdk.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
```

### Type specific methods

#### Boolean
```swift
sdk.getVariableBoolean(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### String
```swift
sdk.getVariableString(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Integer
```swift
sdk.getVariableInteger(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Double
```swift
sdk.getVariableDouble(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Array of strings
```swift
sdk.getVariableArray(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Generic decodable object
```swift
sdk.getVariableObject(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### JSON object
```swift
sdk.getVariableJSON(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

### Logging
By default, Featurevisor will log logs to the for `warn` and `error` levels.

#### Level
```swift
let logger = createLogger(levels: [.error, .warn, .info, .debug])
```
#### Handler
```swift
let logger = createLogger(
        levels: [.error, .warn, .info, .debug],
        handle: { level, message, details in ... })
```

### Refreshing datafile
Refreshing the datafile is convenient when you want to update the datafile in runtime, for example when you want to update the feature variations and variables config without having to restart your application.

It is only possible to refresh datafile in Featurevisor if you are using the datafileUrl option when creating your SDK instance.

#### Manual refresh

```swift
sdk.refresh()
```

#### Refresh by interval
If you want to refresh your datafile every X number of seconds, you can pass the `refreshInterval` option when creating your SDK instance:

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.refreshInterval = 30 // 30 seconds

let featurevisor = try createInstance(options: options)
```

You can stop the interval by calling

```swift
sdk.stopRefreshing()
```

If you want to resume refreshing

```swift
sdk.startRefreshing()
```

### Listening for updates
Every successful refresh will trigger the `onRefresh` option

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onRefresh = { ... }

let featurevisor = try createInstance(options: options)
```

Not every refresh is going to be of a new datafile version. If you want to know if datafile content has changed in any particular refresh, you can listen to `onUpdate` option

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onUpdate = { ... }

let featurevisor = try createInstance(options: options)
```

### Events
Featurevisor SDK implements a simple event emitter that allows you to listen to events that happen in the runtime.

#### Listening to events
You can listen to these events that can occur at various stages in your application

##### ready
When the SDK is ready to be used if used in an asynchronous way involving datafileUrl option

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onReady = { ... }

let featurevisor = try createInstance(options: options)
```

You can also synchronously check if the SDK is ready
```swift
guard sdk.isReady() else {
  // sdk is not ready to be used
}
```

##### activation
When a feature is activated

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onActivation = { ... }

let featurevisor = try createInstance(options: options)
```

### Test runner

@TODO: ...

We should also have an executable as an output of this repository that can be used to run the test specs against the Swift SDK: https://featurevisor.com/docs/testing/

Example command:

```
$ cd path/to/featurevisor-project-with-yamls
$ featurevisor-swift test
```

## License

[MIT](./LICENSE)
