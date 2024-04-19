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
You can fetch the datafile content on your own and just pass it via options.

```swift
import FeaturevisorSDK

let datafileContent: DatafileContent = ...
var options: InstanceOptions = .default
options.datafile = datafileContent

let f = try createInstance(options: options)
```

### Asynchronous
If you want to delegate the responsibility of fetching the datafile to the SDK.

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json" 
let f = try createInstance(options: options)
```

If you need to take further control on how the datafile is fetched, you can pass a custom `handleDatafileFetch` function

```swift
public typealias DatafileFetchHandler = (_ datafileUrl: String) -> Result<DatafileContent, Error>
```

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.handleDatafileFetch = { datafileUrl in
    // you need to return here Result<DatafileContent, Error>
}
let f = try createInstance(options: options)
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

let isEnabled = f.isEnabled(featureKey: featureKey, context: context)
```

### Getting variations
If your feature has any variations defined, you can get evaluate them as follows

```swift
let featureKey = "my_feature";
let context = [
    "userId": .string("123")
]

let variation = f.getVariation(featureKey: featureKey, context: context)
```

### Getting variables
```swift
let featureKey = "my_feature";
let variableKey = "color"
let context = [
    "userId": .string("123")
]
let variable: VariableValue? = f.getVariable(featureKey: featureKey, variableKey: variableKey, context: context)
```

### Type specific methods

#### Boolean
```swift
let booleanVariable: Bool? = f.getVariableBoolean(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### String
```swift
let stringVariable: String? = f.getVariableString(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Integer
```swift
let integerVariable: Int? = f.getVariableInteger(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Double
```swift
let doubleVariable: Double? = f.getVariableDouble(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Array of strings
```swift
let arrayVariable: [String]? = f.getVariableArray(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### Generic decodable object
```swift
let objectVariable: MyDecodableObject? = f.getVariableObject(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

#### JSON object
```swift
let jsonVariable: MyJSONDecodableObject? = f.getVariableJSON(featureKey: FeatureKey, variableKey: VariableKey, context: Context)
```

### Logging
By default, Featurevisor will log logs in console output window for `warn` and `error` levels.

#### Level
```swift
let logger = createLogger(levels: [.error, .warn, .info, .debug])
```
#### Handler
```swift
let logger = createLogger(
        levels: [.error, .warn, .info, .debug],
        handle: { level, message, details in ... })

var options = InstanceOptions.default
options.logger = logger

let f = try createInstance(options: options)
```

### Refreshing datafile
Refreshing the datafile is convenient when you want to update the datafile in runtime, for example when you want to update the feature variations and variables config without having to restart your application.

It is only possible to refresh datafile in Featurevisor if you are using the datafileUrl option when creating your SDK instance.

#### Manual refresh

```swift
f.refresh()
```

#### Refresh by interval
If you want to refresh your datafile every X number of seconds, you can pass the `refreshInterval` option when creating your SDK instance:

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.refreshInterval = 30 // 30 seconds

let f = try createInstance(options: options)
```

You can stop the interval by calling

```swift
f.stopRefreshing()
```

If you want to resume refreshing

```swift
f.startRefreshing()
```

### Listening for updates
Every successful refresh will trigger the `onRefresh` option

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onRefresh = { ... }

let f = try createInstance(options: options)
```

Not every refresh is going to be of a new datafile version. If you want to know if datafile content has changed in any particular refresh, you can listen to `onUpdate` option

```swift
import FeaturevisorSDK

var options: InstanceOptions = .default
options.datafileUrl = "https://cdn.yoursite.com/production/datafile-tag-all.json"
options.onUpdate = { ... }

let f = try createInstance(options: options)
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

let f = try createInstance(options: options)
```

You can also synchronously check if the SDK is ready
```swift
guard f.isReady() else {
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

let f = try createInstance(options: options)
```

### Test runner

@TODO: Work still in progress. Currently we have an early POC.

### Options

```bash
'only-failures'
```

If you are interested to see only the test specs that fail:

Example command:

First you need to install the Swift Test Runner using above steps (until we release official version)
```
$ cd path/to/featurevisor-swift-sdk
$ swift build -c release
$ cd .build/release
$ cp -f FeaturevisorSwiftTestRunner /usr/local/bin/featurevisor-swift-test-runner
```

Now you can usage like below:
```
$ cd path/to/featurevisor-project-with-yamls
$ featurevisor-swift-test-runner test .
```

### Benchmarking
You can measure how fast or slow your SDK evaluations are for particular features.

The `--n` option is used to specify the number of iterations to run the benchmark for.

### Feature
To benchmark evaluating a feature itself if it is enabled or disabled via SDK's `.isEnabled()` method:

```bash
 FeaturevisorTestRunner benchmark \
  --environment staging \
  --feature feature_key \
  --context '{"user_id":"123"}' \
  -n 100
```

### Variation
To benchmark evaluating a feature's variation via SDKs's `.getVariation()` method:

```bash
 FeaturevisorTestRunner benchmark \
  --environment staging \
  --feature feature_key \
  --context '{"user_id":"123"}' \
  --variation \
  -n 100
```

### Variable
To benchmark evaluating a feature's variable via SDKs's `.getVariable()` method:

```bash
 FeaturevisorTestRunner benchmark \
  --environment staging \
  --feature feature_key \
  --variable variable_key \
  --context '{"user_id":"123"}' \
  -n 100
```

### Evaluate
To learn why certain values (like feature and its variation or variables) are evaluated as they are against provided [context](https://featurevisor.com/docs/sdks/javascript/#context):

```bash
 FeaturevisorTestRunner evaluate \
  --environment staging \
  --feature feature_key \
  --feature variable_key \
  --context '{"user_id":"123"}' \
```
This will show you full [evaluation details](https://featurevisor.com/docs/sdks/javascript/#evaluation-details) helping you debug better in case of any confusion.
It is similar to logging in SDKs with debug level. But here instead, we are doing it at CLI directly in our Featurevisor project without having to involve our application(s).

## License

[MIT](./LICENSE)
