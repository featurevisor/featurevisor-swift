---
title: Contributing
description: Learn how to contribute to Featurevisor
---

## Code of Conduct

We have adopted the [Contributor Covenant](https://www.contributor-covenant.org/) as our [Code of Conduct](https://github.com/featurevisor/featurevisor-swift/blob/main/CODE_OF_CONDUCT.md), and we expect project participants to adhere to it.

## Branch organization

You can send your pull requests against the `main` branch.

## Bugs

We use [GitHub Issues](https://github.com/fahad19/featurevisor/issues) for bug reporting.

Before reporting any new ones, please check if it has been reported already.

## License

By contributing to Featurevisor, you agree that your contributions will be licensed under its [MIT license](https://github.com/featurevisor/featurevisor-swift/blob/master/LICENSE).

## Development workflow

Prerequsites:

- [npm](https://www.npmjs.com/) v8+
- [Git](https://git-scm.com/) v2+
- [swift-format](https://github.com/apple/swift-format)

### Local Development

Clone the [repository](https://github.com/featurevisor/featurevisor-swift).

Then on your iOS or tvOS application, import this local package

1. Go to File > Add Packages...
2. Select "Add Local" at the bottom of the modal
3. Select the folder where you cloned this project
3. Select your project in "Add to project" option menu

Once the package has been added, you can use it like this

```swift
import FeaturevisorSDK

let featurevisorOptions = FeaturevisorSDK.InstanceOptions(
    datafileUrl: "https://featurevisor-example-cloudflare.pages.dev/production/datafile-tag-all.json"
)
if let featurevisorSdk = FeaturevisorSDK.createInstance(options: featurevisorOptions) {
    let featureKey = "headerBanner";
    let showBanner = featurevisorSdk.getVariation(featureKey: featureKey, context: [:]);

    print(showBanner ?? "not found")
}
```

When you build your Xcode project, FeaturevisorSDK will be automatically built.

#### Throubleshooting

No such module 'FeaturevisorSDK'

If you see this error, please double-check the target of your app:
1. Go to the "General" tab in your app's target settings in Xcode.
1. Scroll down to "Frameworks, Libraries, and Embedded Content"
1. Make sure FeaturevisorSDK is listed and set to "Do Not Embed" (because it's a Swift package).

### Tests

```
$ make test
```

### Build in isolation

You can also build your project outside of Xcode with

```
$ make build
```

### Pull Requests

Send Pull Requests against the `main` branch.
